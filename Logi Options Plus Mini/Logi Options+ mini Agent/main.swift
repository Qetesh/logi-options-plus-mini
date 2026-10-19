//
//  main.swift
//  Logi Options+ mini Agent
//
//  Created by Qetesh Wong on 2025/8/11.
//

import Foundation
import os
import Security

let logger = Logger(subsystem: "io.qetesh.logi-options-plus-mini.agent", category: "Default")

/// The only client allowed to use this privileged agent.
///
/// Keep the Team ID and bundle identifier in the requirement instead of
/// matching the certificate's common name. The common name can change when a
/// signing certificate is renewed, while the Team ID identifies the developer
/// account and the bundle identifier identifies this application.
private enum TrustedClient {
    static let teamIdentifier = "4H3G2UG993"
    static let bundleIdentifier = "io.qetesh.Logi-Options-Plus-mini"

    static let codeRequirement =
        "anchor apple generic and identifier \"\(bundleIdentifier)\" and certificate leaf[subject.OU] = \"\(teamIdentifier)\""
}

/// 定义 XPC 服务的 API 协议
@objc protocol AgentProtocol {
    /// 运行命令并返回结果
    func runCommand(_ command: String, reply: @escaping (Bool, String) -> Void)
    
    /// Ping 命令用于状态检查
    func ping(reply: @escaping (String) -> Void)
}

/// 实现 XPC 服务的核心业务逻辑
class Agent: NSObject, AgentProtocol {
    
    override init() {
        super.init()
        logger.info("Agent: Agent created")
    }
    
    /// 运行命令并返回结果
    func runCommand(_ command: String, reply: @escaping (Bool, String) -> Void) {
        logger.info("Agent: [runCommand] running command: \(command)")
        
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.launchPath = "/bin/zsh"
            process.arguments = ["-c", command]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let success = process.terminationStatus == 0
                
                logger.info("Agent: [runCommand] command executed, exit code: \(process.terminationStatus)")
                reply(success, output)
            } catch {
                logger.error("Agent: [runCommand] execution failed: \(error.localizedDescription)")
                reply(false, "execution failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// 实现 Ping 功能
    func ping(reply: @escaping (String) -> Void) {
        logger.info("Agent: [ping] handling ping request")
        let response = "pong"
        logger.info("Agent: [ping] returning response: \(response)")
        reply(response)
    }
}

/// 实现 NSXPCListenerDelegate 来处理新的连接
class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    override init() {
        super.init()
        logger.info("Agent: ServiceDelegate created")
    }
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        logger.info("Agent: [shouldAcceptNewConnection] received new connection request")
        logger.info("Agent: [shouldAcceptNewConnection] process ID: \(newConnection.processIdentifier)")

        // Let the system validate the client against the code requirement. This uses the
        // connection's audit token rather than its PID, so the check cannot be raced by
        // PID reuse, and it applies to every message received on the connection.
        newConnection.setCodeSigningRequirement(TrustedClient.codeRequirement)
        
        // 设置远程对象接口
        newConnection.exportedInterface = NSXPCInterface(with: AgentProtocol.self)
        logger.info("Agent: [shouldAcceptNewConnection] remote object interface set")
        
        // 创建并导出服务对象
        let exportedObject = Agent()
        newConnection.exportedObject = exportedObject
        logger.info("Agent: [shouldAcceptNewConnection] exported object set: \(exportedObject)")
        
        // 设置中断处理器
        newConnection.interruptionHandler = {
            logger.info("Agent: [interruptionHandler] XPC connection interrupted")
        }
        
        // 设置无效化处理器
        newConnection.invalidationHandler = {
            logger.info("Agent: [invalidationHandler] XPC connection invalidated")
        }
        
        // 启动连接
        newConnection.resume()
        logger.info("Agent: [shouldAcceptNewConnection] connection activated and started listening")
        
        return true
    }
}

/// 主程序入口
func main() {
    logger.info("Agent: ================================")
    logger.info("Agent: starting Logi Options+ mini Agent")
    logger.info("Agent: version: 1.0.0")
    logger.info("Agent: process ID: \(getpid())")
    logger.info("Agent: user ID: \(getuid())")
    logger.info("Agent: ================================")
    
    // 创建服务代理
    let delegate = ServiceDelegate()
    logger.info("Agent: ServiceDelegate created")
    
    // 创建 XPC 监听器，使用 Mach 服务名称
    let listener = NSXPCListener(machServiceName: "io.qetesh.logi-options-plus-mini.agent")
    logger.info("Agent: NSXPCListener created, service name: io.qetesh.logi-options-plus-mini.agent")
    
    // 设置代理
    listener.delegate = delegate
    logger.info("Agent: Listener delegate set")
    
    // 开始监听
    logger.info("Agent: starting to listen for XPC connections...")
    listener.resume()
    logger.info("Agent: Listener activated, Agent service is running")
    
    // 保持运行循环
    logger.info("Agent: entering run loop, waiting for connections...")
    RunLoop.main.run()
}

// 启动主程序
main()
