/// Selects the synchronization backend used by `DBThreadSafeContainer`.
public enum DBThreadSafeLock: Sendable {
    /// Uses the `pthread_rwlock_t` backend. Multiple readers may proceed concurrently.
    case pthreadRWLock

#if canImport(Synchronization)
    /// Uses the `Synchronization.Mutex` backend.
    @available(iOS 18, macCatalyst 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
    case mutex
#endif
}
