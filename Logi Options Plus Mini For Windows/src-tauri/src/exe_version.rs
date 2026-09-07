//! 读取 exe 文件属性中的版本信息（Windows 版本资源），用于判断安装程序支持的参数。
//!
//! 安装程序参数是否受支持与其版本相关（如自 2.7.961922 起不再支持 AI Prompt Builder 参数），
//! 需要在安装包下载完成后，根据 exe 文件属性中的版本判断是否传递对应参数。

/// 按安装程序版本判断的参数支持规则。
///
/// 后续如有其他安装程序参数需要按版本判断支持性，只需在 `PARAM_SUPPORT_RULES`
/// 中追加规则，安装时的参数过滤（`installer::install_internal`）和前端的
/// 选项禁用（`installer-param-support` 事件）都会自动应用新规则。
pub struct ParamSupportRule {
    /// 安装程序参数名（与前端功能项 id 一致）
    pub param: &'static str,
    /// 不再受支持的起始版本（大于等于该版本即不支持）
    pub unsupported_since: [u64; 3],
}

/// 参数支持规则表。
pub const PARAM_SUPPORT_RULES: &[ParamSupportRule] = &[
    ParamSupportRule {
        param: "aipromptbuilder",
        // 安装程序自 2.7.961922 起不再支持 AI Prompt Builder 参数
        unsupported_since: [2, 7, 961922],
    },
];

/// 将版本字符串按 "." 分段解析为数字（每段取前导数字，忽略其余字符）。
fn parse_version_parts(version: &str) -> Vec<u64> {
    version
        .split('.')
        .map(|part| {
            let digits: String = part.chars().take_while(|c| c.is_ascii_digit()).collect();
            digits.parse::<u64>().unwrap_or(0)
        })
        .collect()
}

/// 判断 version 是否大于等于 threshold（逐段数值比较，缺省段按 0 处理）。
pub fn version_at_least(version: &str, threshold: &[u64]) -> bool {
    let parts = parse_version_parts(version);
    for (i, &t) in threshold.iter().enumerate() {
        let v = parts.get(i).copied().unwrap_or(0);
        if v > t {
            return true;
        }
        if v < t {
            return false;
        }
    }
    true
}

/// 根据安装程序版本计算各参数的支持状态。
/// 返回 (规则, 是否受支持) 列表，与 `PARAM_SUPPORT_RULES` 一一对应。
pub fn evaluate_param_support(version: &str) -> Vec<(&'static ParamSupportRule, bool)> {
    PARAM_SUPPORT_RULES
        .iter()
        .map(|rule| (rule, !version_at_least(version, &rule.unsupported_since)))
        .collect()
}

/// 将版本数字段格式化为点分字符串（用于日志）。
pub fn format_version(parts: &[u64]) -> String {
    parts
        .iter()
        .map(|p| p.to_string())
        .collect::<Vec<_>>()
        .join(".")
}

/// 读取 exe 文件属性中的版本字符串。
///
/// 依次尝试版本资源 StringFileInfo 中的 FileVersion、ProductVersion 字符串，
/// 均不可用时回退到 VS_FIXEDFILEINFO 中的二进制版本号。
#[cfg(windows)]
pub fn get_file_version_string(path: &std::path::Path) -> Option<String> {
    use std::os::windows::ffi::OsStrExt;

    // VS_FIXEDFILEINFO 布局（winver.h）
    #[repr(C)]
    #[allow(non_snake_case)]
    struct VS_FIXEDFILEINFO {
        dwSignature: u32,
        dwStrucVersion: u32,
        dwFileVersionMS: u32,
        dwFileVersionLS: u32,
        dwProductVersionMS: u32,
        dwProductVersionLS: u32,
        dwFileFlagsMask: u32,
        dwFileFlags: u32,
        dwFileOS: u32,
        dwFileType: u32,
        dwFileSubtype: u32,
        dwFileDateMS: u32,
        dwFileDateLS: u32,
    }

    // LANGANDCODEPAGE 布局（verrsrc.h）
    #[repr(C)]
    #[allow(non_snake_case)]
    struct LANGANDCODEPAGE {
        wLanguage: u16,
        wCodePage: u16,
    }

    #[link(name = "version")]
    unsafe extern "system" {
        fn GetFileVersionInfoSizeW(lptstrFilename: *const u16, lpdwHandle: *mut u32) -> u32;
        fn GetFileVersionInfoW(
            lptstrFilename: *const u16,
            dwHandle: u32,
            dwLen: u32,
            lpData: *mut std::ffi::c_void,
        ) -> i32;
        fn VerQueryValueW(
            pBlock: *const std::ffi::c_void,
            lpSubBlock: *const u16,
            lplpBuffer: *mut *mut std::ffi::c_void,
            puLen: *mut u32,
        ) -> i32;
    }

    unsafe {
        let path_w: Vec<u16> = path.as_os_str().encode_wide().chain(Some(0)).collect();

        let size = GetFileVersionInfoSizeW(path_w.as_ptr(), std::ptr::null_mut());
        if size == 0 {
            return None;
        }

        let mut data = vec![0u8; size as usize];
        if GetFileVersionInfoW(path_w.as_ptr(), 0, size, data.as_mut_ptr().cast()) == 0 {
            return None;
        }

        // 读取语言/代码页翻译表
        let query_translate: Vec<u16> = "\\VarFileInfo\\Translation\u{0}".encode_utf16().collect();
        let mut translate: *mut LANGANDCODEPAGE = std::ptr::null_mut();
        let mut translate_len: u32 = 0;
        if VerQueryValueW(
            data.as_ptr().cast(),
            query_translate.as_ptr(),
            (&mut translate as *mut *mut LANGANDCODEPAGE).cast(),
            &mut translate_len,
        ) != 0
            && !translate.is_null()
            && translate_len as usize >= std::mem::size_of::<LANGANDCODEPAGE>()
        {
            let count = (translate_len as usize / std::mem::size_of::<LANGANDCODEPAGE>()).max(1);
            let translations = std::slice::from_raw_parts(translate, count);

            // 依次尝试文件版本 / 产品版本字符串
            for key in ["FileVersion", "ProductVersion"] {
                for t in translations {
                    let sub_block = format!(
                        "\\StringFileInfo\\{:04x}{:04x}\\{}\u{0}",
                        t.wLanguage, t.wCodePage, key
                    );
                    let query: Vec<u16> = sub_block.encode_utf16().collect();
                    let mut value: *mut u16 = std::ptr::null_mut();
                    let mut value_len: u32 = 0;
                    if VerQueryValueW(
                        data.as_ptr().cast(),
                        query.as_ptr(),
                        (&mut value as *mut *mut u16).cast(),
                        &mut value_len,
                    ) != 0
                        && !value.is_null()
                        && value_len > 0
                    {
                        let raw = std::slice::from_raw_parts(value, value_len as usize);
                        let text = String::from_utf16_lossy(raw)
                            .trim_end_matches('\u{0}')
                            .trim()
                            .to_string();
                        if !text.is_empty() {
                            return Some(text);
                        }
                    }
                }
            }
        }

        // 回退：读取 VS_FIXEDFILEINFO 中的二进制文件版本号
        let query_root: Vec<u16> = "\\\u{0}".encode_utf16().collect();
        let mut ffi_ptr: *mut VS_FIXEDFILEINFO = std::ptr::null_mut();
        let mut ffi_len: u32 = 0;
        if VerQueryValueW(
            data.as_ptr().cast(),
            query_root.as_ptr(),
            (&mut ffi_ptr as *mut *mut VS_FIXEDFILEINFO).cast(),
            &mut ffi_len,
        ) != 0
            && !ffi_ptr.is_null()
            && ffi_len as usize >= std::mem::size_of::<VS_FIXEDFILEINFO>()
        {
            let ffi = &*ffi_ptr;
            if ffi.dwSignature == 0xFEEF04BD {
                return Some(format!(
                    "{}.{}.{}.{}",
                    ffi.dwFileVersionMS >> 16,
                    ffi.dwFileVersionMS & 0xFFFF,
                    ffi.dwFileVersionLS >> 16,
                    ffi.dwFileVersionLS & 0xFFFF
                ));
            }
        }

        None
    }
}

#[cfg(not(windows))]
pub fn get_file_version_string(_path: &std::path::Path) -> Option<String> {
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version_at_least() {
        let threshold = &PARAM_SUPPORT_RULES[0].unsupported_since;
        assert!(version_at_least("2.7.961922", threshold));
        assert!(version_at_least("2.7.961922.0", threshold));
        assert!(version_at_least("2.10.998888", threshold));
        assert!(version_at_least("3.0.0", threshold));
        assert!(!version_at_least("2.7.961921", threshold));
        assert!(!version_at_least("2.6.970000", threshold));
        assert!(!version_at_least("2.7.96", threshold));
        assert!(!version_at_least("1.9.999999", threshold));
        // 带附加文字的版本字符串
        assert!(version_at_least("2.7.961922 beta", threshold));
    }

    #[test]
    fn test_evaluate_param_support() {
        let support = evaluate_param_support("2.7.961922");
        assert_eq!(support.len(), PARAM_SUPPORT_RULES.len());
        assert!(support
            .iter()
            .any(|(rule, supported)| rule.param == "aipromptbuilder" && !*supported));

        let support = evaluate_param_support("2.6.970000");
        assert!(support
            .iter()
            .any(|(rule, supported)| rule.param == "aipromptbuilder" && *supported));
    }
}
