//
//  AgentManager.swift
//  Logi Options+ mini
//
//  Created by AI Assistant on 2025/1/14.
//  基于苹果官方 SMAppService 示例简化实现
//

import Foundation
import ServiceManagement
import Logging

/// 定义 XPC 服务的 API 协议（与 Agent 端保持一致）
@objc protocol AgentProtocol {
    /// 运行命令并返回结果
    func runCommand(_ command: String, reply: @escaping (Bool, String) -> Void)
    
    /// Ping 命令用于状态检查
    func ping(reply: @escaping (String) -> Void)
}

class AgentManager: ObservableObject {
    static let shared = AgentManager()
    
    @Published var isAgentInstalled = false
    @Published var isAgentRunning = false
    @Published var statusMessage = ""
    
    private let agentIdentifier = "io.qetesh.logi-options-plus-mini.agent"
    private let serviceName = "io.qetesh.logi-options-plus-mini.agent"
    
    private init() {
        // Agent状态检查移至应用启动时执行
    }
    
    // MARK: - Public Methods
    
    /// 安装 Agent
    func installAgent() async throws {
        Logger.app.info("\(String(localized: "Installing app helper..."))")
        await MainActor.run {
            statusMessage = "Installing app helper..."
        }
        
        do {
            // 使用 SMAppService 注册 LaunchDaemon (需要 root 权限执行命令)
            let service = SMAppService.daemon(plistName: "\(agentIdentifier).plist")
            
            Logger.app.debug("\(String(localized: "Before registration status")): \(service.status.rawValue)")
            try service.register()
            
            // 立即检查注册后的状态
            let newStatus = service.status
            
            await MainActor.run {
                isAgentInstalled = true
                statusMessage = "App helper installed successfully"
            }
            
            // 检查是否需要用户授权
            if newStatus == .requiresApproval {
                Logger.app.warning("\(String(localized: "Requires user approval"))")
                await MainActor.run {
                    statusMessage = "❌ Approval required in Notification Center or System Settings → General → Login Items & Extensions"
                }
            } else if newStatus == .enabled {
                Logger.app.info("\(String(localized: "Agent enabled"))")
                await MainActor.run {
                    statusMessage = "App helper is ready"
                }
            }
            
        } catch {
            Logger.app.error("\(String(localized: "Agent registration failed")): \(error)")
            Logger.app.debug("\(String(localized: "Error details")): \(error)")
            await MainActor.run {
                statusMessage = "App helper installation failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// 卸载 Agent
    func uninstallAgent() async throws {
        Logger.app.info("\(String(localized: "Removing app helper..."))")
        await MainActor.run {
            statusMessage = "Removing app helper..."
        }
        
        do {
            // 使用 SMAppService 注销 LaunchDaemon
            let service = SMAppService.daemon(plistName: "\(agentIdentifier).plist")
            
            Logger.app.debug("\(String(localized: "Before uninstallation status")): \(service.status.rawValue)")
            try await service.unregister()
            
            await MainActor.run {
                isAgentInstalled = false
                isAgentRunning = false
                statusMessage = "App helper removed successfully"
            }
            
        } catch {
            Logger.app.error("\(String(localized: "Agent unregistration failed")): \(error)")
            Logger.app.debug("\(String(localized: "Error details")): \(error)")
            await MainActor.run {
                statusMessage = "App helper removal failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// 通过 Agent 运行命令
    func runCommandThroughAgent(command: String) async throws -> (Bool, String) {
        Logger.app.debug("\(String(localized: "Running command with elevated privileges")): \(command)")
        
        guard isAgentRunning else {
            throw NSError(domain: "AgentManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "App helper is not running"
            ])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Flag to ensure continuation is only resumed once
            var hasResumed = false
            let resumeLock = NSLock()
            
            func safeResume(with result: Result<(Bool, String), Error>) {
                resumeLock.lock()
                defer { resumeLock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(with: result)
            }
            
            Logger.app.debug("\(String(localized: "Creating XPC connection to service")): \(self.serviceName)")
            let connection = NSXPCConnection(machServiceName: serviceName, options: [.privileged])
            
            connection.remoteObjectInterface = NSXPCInterface(with: AgentProtocol.self)
            
            connection.interruptionHandler = {
                Logger.app.warning("\(String(localized: "Connection to app helper interrupted"))")
                safeResume(with: .failure(NSError(domain: "AgentManager", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Connection to app helper interrupted"
                ])))
            }
            
            connection.invalidationHandler = {
                // Also called when we explicitly close a completed request's connection.
                // This describes the connection lifecycle, not whether the agent is running.
                Logger.app.debug("\(String(localized: "XPC connection closed"))")
            }
            
            connection.resume()
            
            guard let proxy = connection.remoteObjectProxy as? AgentProtocol else {
                Logger.app.error("\(String(localized: "Failed to connect to app helper"))")
                connection.invalidate()
                safeResume(with: .failure(NSError(domain: "AgentManager", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to connect to app helper"
                ])))
                return
            }
            
            Logger.app.debug("\(String(localized: "Executing via app helper..."))")
            proxy.runCommand(command) { success, output in
                Logger.app.debug("\(String(localized: "Command execution result")): \(success ? String(localized: "Success") : String(localized: "Failed"))")
                Logger.app.debug("\(String(localized: "Command output")): \(output)")
                safeResume(with: .success((success, output)))
                connection.invalidate()
            }
        }
    }
    

    
    /// 检查 Agent 状态
    func checkAgentStatus() {
        let service = SMAppService.daemon(plistName: "\(agentIdentifier).plist")
        let status = service.status
        
        // 将状态转换为具体的名称用于日志输出
        let statusName: String
        let installed: Bool
        switch status {
        case .notRegistered:
            statusName = "notRegistered"
            installed = false
        case .enabled:
            statusName = "enabled"
            installed = true
        case .requiresApproval:
            statusName = "requiresApproval"
            installed = true
        case .notFound:
            statusName = "notFound"
            installed = false
        @unknown default:
            statusName = "unknown(\(status.rawValue))"
            installed = false
        }
        
        Logger.app.debug("\(String(localized: "App helper status")): \(statusName)")
        
        // 在主线程上更新UI状态
        DispatchQueue.main.async {
            self.isAgentInstalled = installed
            
            // 如果Agent已安装，检查运行状态
            if installed {
                Logger.app.debug("\(String(localized: "App helper installed, checking status..."))")
                self.checkAgentRunningStatus()
            } else {
                self.isAgentRunning = false
                self.statusMessage = status == .requiresApproval ? "Requires user approval" : "App helper not installed"
                Logger.app.debug("\(String(localized: "App helper status")): \(self.statusMessage)")
            }
        }
    }
        
    func checkAgentRunningStatus() {
        guard isAgentInstalled else {
            DispatchQueue.main.async {
                self.isAgentRunning = false
            }
            return
        }
                
        // 使用协议方式进行 ping 检查
        Task {
            do {
                let isRunning = try await pingAgent()
                Logger.app.debug("\(String(localized: "App helper status")): \(isRunning ? String(localized: "Yes") : String(localized: "No"))")
                
                await MainActor.run {
                    self.isAgentRunning = isRunning
                    if self.isAgentInstalled && isRunning {
                        self.statusMessage = "App helper is working"
                    } else if self.isAgentInstalled {
                        self.statusMessage = "App helper is installed but not running"
                    }
                }
            } catch {
                Logger.app.warning("\(String(localized: "App helper connection check failed")): \(error)")
                
                await MainActor.run {
                    self.isAgentRunning = false
                    if self.isAgentInstalled {
                        self.statusMessage = "App helper is installed but not running"
                    }
                }
            }
        }
    }
    
    /// 使用协议方式 ping Agent
    private func pingAgent() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            // Flag to ensure continuation is only resumed once
            var hasResumed = false
            let resumeLock = NSLock()
            
            func safeResume(returning value: Bool) {
                resumeLock.lock()
                defer { resumeLock.unlock() }
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: value)
            }
            
            // LaunchDaemon 需要 .privileged 选项
            let connection = NSXPCConnection(machServiceName: serviceName, options: [.privileged])
            
            connection.remoteObjectInterface = NSXPCInterface(with: AgentProtocol.self)
            
            connection.interruptionHandler = {
                safeResume(returning: false)
            }
            
            connection.invalidationHandler = {
                Logger.app.trace("\(String(localized: "XPC connection closed"))")
            }
            
            connection.resume()
            
            guard let proxy = connection.remoteObjectProxy as? AgentProtocol else {
                Logger.app.debug("\(String(localized: "Failed to establish connection to app helper"))")
                connection.invalidate()
                safeResume(returning: false)
                return
            }
            
            proxy.ping { response in
                Logger.app.debug("\(String(localized: "App helper responded")): \(response)")
                let pingSuccess = response == "pong"
                safeResume(returning: pingSuccess)
                connection.invalidate()
            }
        }
    }
}
