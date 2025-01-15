import Foundation
import Capacitor

@objc(Stockfish)
public class Stockfish: CAPPlugin {
    
    private var stockfish: StockfishBridge?
    private var isInit = false
    private var onStartedCallback: CAPPluginCall?
    
    private let template = "{\"output\": \"%@\"}"
    @objc public func sendOutput(_ output: String) {
        print("Sending output \(output)")
        if (onStartedCallback != nil) {
            print("Resolving the started callback!")
            onStartedCallback?.resolve()
            onStartedCallback = nil
        }
        bridge?.triggerWindowJSEvent(eventName: "stockfish", data: String(format: template, output))
    }

    @objc override public func load() {
        var onPauseWorkItem: DispatchWorkItem?

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            if (self!.isInit) {
                onPauseWorkItem = DispatchWorkItem {
                    self?.stockfish?.cmd("stop")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 60 * 3, execute: onPauseWorkItem!)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            if (self!.isInit) {
                onPauseWorkItem?.cancel()
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            if (self!.isInit) {
                self?.stockfish?.cmd("stop")
                self?.stockfish?.exit()
                self?.isInit = false
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func getCPUArch(_ call: CAPPluginCall) {
        call.resolve([
            "value": StockfishBridge.getCPUType() ?? "unknown"
        ])
    }

    @objc func getMaxMemory(_ call: CAPPluginCall) {
        // allow max 1/16th of total mem
        let maxMemInMb = (ProcessInfo().physicalMemory / 16) / (1024 * 1024)
        call.resolve([
            "value": maxMemInMb
        ])
    }
    
    @objc func getProcessorCount(_ call: CAPPluginCall) {
        let maxConcurrency = ProcessInfo().processorCount
        call.resolve([
            "value": maxConcurrency
        ])
    }

    @objc func start(_ call: CAPPluginCall) {
        print("Setting the callback thing")
        call.keepAlive = true
        if (!isInit) {
            stockfish = StockfishBridge(plugin: self)
            stockfish?.start()
            isInit = true
        }
        self.onStartedCallback = call
    }

    @objc func cmd(_ call: CAPPluginCall) {
        if (isInit) {
            guard let cmd = call.options["cmd"] as? String else {
                call.reject("Must provide a cmd")
                return
            }
            print("Sending cmd \(cmd)")

            stockfish?.cmd(cmd)
            call.resolve()
        } else {
            call.reject("You must call start before anything else")
        }
    }
    
    @objc func exit(_ call: CAPPluginCall) {
        if (isInit) {
            stockfish?.cmd("quit")
            stockfish?.exit()
            isInit = false
        }
        call.resolve()
    }
}
