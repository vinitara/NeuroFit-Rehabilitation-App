import Foundation
import Combine

class TimerLogic: ObservableObject {
    @Published var remainingSeconds: Int
    @Published var isPaused = false
    @Published var isFinished = false
    
    private var cancellable: AnyCancellable?
    
    init(durationMinutes: Int) {
        self.remainingSeconds = durationMinutes * 60
    }

    func start() {
        stop()
        
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if !self.isPaused && !self.isFinished {
                    if self.remainingSeconds > 0 {
                        self.remainingSeconds -= 1
                        print("Timer Tick: \(self.remainingSeconds)")
                    } else {
                        self.isFinished = true
                        self.stop()
                    }
                }
            }
    }
    
    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }
}
