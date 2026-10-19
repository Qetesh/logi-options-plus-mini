//! 校验下载的安装程序的 Authenticode 签名。
//!
//! 安装程序下载到当前用户可写的临时目录后会以管理员权限执行，
//! 执行前确认签名有效且签名者为 Logitech，避免执行被替换的文件。

/// 期望的签名者证书组织名（Subject 中的 O 字段）
pub const EXPECTED_SIGNER_ORGANIZATION: &str = "Logitech Inc";

/// 校验文件的 Authenticode 签名是否有效，并返回签名者证书的组织名。
#[cfg(windows)]
pub fn get_signer_organization(path: &std::path::Path) -> Result<String, String> {
    use std::ffi::c_void;
    use std::os::windows::ffi::OsStrExt;

    #[repr(C)]
    struct Guid {
        data1: u32,
        data2: u16,
        data3: u16,
        data4: [u8; 8],
    }

    // WINTRUST_FILE_INFO 布局（wintrust.h）
    #[repr(C)]
    #[allow(non_snake_case)]
    struct WINTRUST_FILE_INFO {
        cbStruct: u32,
        pcwszFilePath: *const u16,
        hFile: *mut c_void,
        pgKnownSubject: *mut Guid,
    }

    // WINTRUST_DATA 布局（wintrust.h）
    #[repr(C)]
    #[allow(non_snake_case)]
    struct WINTRUST_DATA {
        cbStruct: u32,
        pPolicyCallbackData: *mut c_void,
        pSIPClientData: *mut c_void,
        dwUIChoice: u32,
        fdwRevocationChecks: u32,
        dwUnionChoice: u32,
        pFile: *mut WINTRUST_FILE_INFO,
        dwStateAction: u32,
        hWVTStateData: *mut c_void,
        pwszURLReference: *mut u16,
        dwProvFlags: u32,
        dwUIContext: u32,
        pSignatureSettings: *mut c_void,
    }

    // CRYPT_PROVIDER_SGNR 的前几个字段（wintrust.h），只读取到 pasCertChain
    #[repr(C)]
    #[allow(non_snake_case)]
    struct CRYPT_PROVIDER_SGNR {
        cbStruct: u32,
        sftVerifyAsOf: [u32; 2],
        csCertChain: u32,
        pasCertChain: *mut CRYPT_PROVIDER_CERT,
    }

    // CRYPT_PROVIDER_CERT 的前几个字段（wintrust.h），只读取到 pCert
    #[repr(C)]
    #[allow(non_snake_case)]
    struct CRYPT_PROVIDER_CERT {
        cbStruct: u32,
        pCert: *const c_void,
    }

    const WTD_UI_NONE: u32 = 2;
    const WTD_REVOKE_NONE: u32 = 0;
    const WTD_CHOICE_FILE: u32 = 1;
    const WTD_STATEACTION_VERIFY: u32 = 1;
    const WTD_STATEACTION_CLOSE: u32 = 2;
    const WTD_CACHE_ONLY_URL_RETRIEVAL: u32 = 0x1000;
    const CERT_NAME_ATTR_TYPE: u32 = 3;
    const SZ_OID_ORGANIZATION_NAME: &[u8] = b"2.5.4.10\0";

    #[link(name = "wintrust")]
    unsafe extern "system" {
        fn WinVerifyTrust(hwnd: *mut c_void, pgActionID: *mut Guid, pWVTData: *mut c_void) -> i32;
        fn WTHelperProvDataFromStateData(hStateData: *mut c_void) -> *mut c_void;
        fn WTHelperGetProvSignerFromChain(
            pProvData: *mut c_void,
            idxSigner: u32,
            fCounterSigner: i32,
            idxCounterSigner: u32,
        ) -> *mut CRYPT_PROVIDER_SGNR;
    }

    #[link(name = "crypt32")]
    unsafe extern "system" {
        fn CertGetNameStringW(
            pCertContext: *const c_void,
            dwType: u32,
            dwFlags: u32,
            pvTypePara: *const c_void,
            pszNameString: *mut u16,
            cchNameString: u32,
        ) -> u32;
    }

    // WINTRUST_ACTION_GENERIC_VERIFY_V2
    let mut action = Guid {
        data1: 0x00aa_c56b,
        data2: 0xcd44,
        data3: 0x11d0,
        data4: [0x8c, 0xc2, 0x00, 0xc0, 0x4f, 0xc2, 0x95, 0xee],
    };

    let path_w: Vec<u16> = path.as_os_str().encode_wide().chain(Some(0)).collect();
    let mut file_info = WINTRUST_FILE_INFO {
        cbStruct: std::mem::size_of::<WINTRUST_FILE_INFO>() as u32,
        pcwszFilePath: path_w.as_ptr(),
        hFile: std::ptr::null_mut(),
        pgKnownSubject: std::ptr::null_mut(),
    };
    let mut data = WINTRUST_DATA {
        cbStruct: std::mem::size_of::<WINTRUST_DATA>() as u32,
        pPolicyCallbackData: std::ptr::null_mut(),
        pSIPClientData: std::ptr::null_mut(),
        dwUIChoice: WTD_UI_NONE,
        fdwRevocationChecks: WTD_REVOKE_NONE,
        dwUnionChoice: WTD_CHOICE_FILE,
        pFile: &mut file_info,
        dwStateAction: WTD_STATEACTION_VERIFY,
        hWVTStateData: std::ptr::null_mut(),
        pwszURLReference: std::ptr::null_mut(),
        dwProvFlags: WTD_CACHE_ONLY_URL_RETRIEVAL,
        dwUIContext: 0,
        pSignatureSettings: std::ptr::null_mut(),
    };

    unsafe {
        let status = WinVerifyTrust(
            std::ptr::null_mut(),
            &mut action,
            (&mut data as *mut WINTRUST_DATA).cast(),
        );

        let result = if status != 0 {
            Err(format!("Invalid signature (WinVerifyTrust: 0x{:08X})", status as u32))
        } else {
            // 从校验状态中取出签名者证书，读取其组织名
            let prov_data = WTHelperProvDataFromStateData(data.hWVTStateData);
            let signer = if prov_data.is_null() {
                std::ptr::null_mut()
            } else {
                WTHelperGetProvSignerFromChain(prov_data, 0, 0, 0)
            };

            if signer.is_null() || (*signer).csCertChain == 0 || (*signer).pasCertChain.is_null() {
                Err("Could not read signer certificate".to_string())
            } else {
                let cert = (*(*signer).pasCertChain).pCert;
                let mut buf = [0u16; 256];
                let len = CertGetNameStringW(
                    cert,
                    CERT_NAME_ATTR_TYPE,
                    0,
                    SZ_OID_ORGANIZATION_NAME.as_ptr().cast(),
                    buf.as_mut_ptr(),
                    buf.len() as u32,
                );
                // 返回值包含结尾的 \0
                Ok(String::from_utf16_lossy(&buf[..(len as usize).saturating_sub(1)]))
            }
        };

        // 释放 WinVerifyTrust 分配的状态
        data.dwStateAction = WTD_STATEACTION_CLOSE;
        WinVerifyTrust(
            std::ptr::null_mut(),
            &mut action,
            (&mut data as *mut WINTRUST_DATA).cast(),
        );

        result
    }
}

#[cfg(not(windows))]
pub fn get_signer_organization(_path: &std::path::Path) -> Result<String, String> {
    Err("Signature verification is only supported on Windows".to_string())
}

/// 确认安装程序由 Logitech 签名，否则返回错误。
pub fn verify_installer(path: &std::path::Path) -> Result<(), String> {
    let organization = get_signer_organization(path)
        .map_err(|e| format!("Installer signature check failed: {}", e))?;

    if organization != EXPECTED_SIGNER_ORGANIZATION {
        return Err(format!(
            "Installer signature check failed: unexpected signer \"{}\"",
            organization
        ));
    }
    Ok(())
}
