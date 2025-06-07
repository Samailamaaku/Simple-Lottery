(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-no-active-lottery (err u101))
(define-constant err-already-participating (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-lottery-in-progress (err u104))
(define-constant err-lottery-expired (err u105))

(define-data-var current-lottery-id uint u0)
(define-data-var active-lottery bool false)

(define-map lotteries uint {
    entry-fee: uint,
    end-block: uint,
    total-pool: uint,
    winner: (optional principal),
    participant-count: uint
})

(define-map lottery-participants uint (list 50 principal))
(define-map participant-status {lottery-id: uint, participant: principal} bool)

(define-read-only (get-lottery-info)
    (let ((id (var-get current-lottery-id)))
        (map-get? lotteries id)
    )
)

(define-read-only (is-participant (user principal))
    (default-to 
        false
        (map-get? participant-status {lottery-id: (var-get current-lottery-id), participant: user})
    )
)

(define-read-only (get-lottery-history (id uint))
    (map-get? lotteries id)
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-all-participants)
    (map-get? lottery-participants (var-get current-lottery-id))
)

(define-private (generate-random-number (seed uint))
    (let (
        (current-block-hash (get-stacks-block-info? id-header-hash stacks-block-height))
        (prev-block-hash (get-stacks-block-info? id-header-hash (- stacks-block-height u1)))
        (participant-count (default-to u0 (get participant-count (map-get? lotteries (var-get current-lottery-id)))))
    )
        (mod (+ 
            (default-to u0 (get-stacks-block-info? time stacks-block-height))
            ;; (default-to u0 seed)
            participant-count
        ) participant-count)
    )
)

(define-public (start-lottery (fee uint) (duration uint))
    (let ((lottery-id (+ (var-get current-lottery-id) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (var-get active-lottery)) err-lottery-in-progress)
        (asserts! (> fee u0) err-insufficient-funds)
        
        (map-set lotteries lottery-id {
            entry-fee: fee,
            end-block: (+ stacks-block-height duration),
            total-pool: u0,
            winner: none,
            participant-count: u0
        })
        
        (var-set current-lottery-id lottery-id)
        (var-set active-lottery true)
        (ok true)
    )
)

(define-public (enter-lottery)
    (let (
        (lottery (unwrap! (get-lottery-info) err-no-active-lottery))
        (fee (get entry-fee lottery))
        (current-participants (unwrap! (get-all-participants) err-no-active-lottery))
    )
        (asserts! (var-get active-lottery) err-no-active-lottery)
        (asserts! (not (is-participant tx-sender)) err-already-participating)
        (asserts! (<= stacks-block-height (get end-block lottery)) err-lottery-expired)
        ;; (asserts! (< (len current-participants) u50) u100)
        
        (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))
        
        ;; (map-set lottery-participants 
        ;;     (var-get current-lottery-id)
        ;;     (append current-participants tx-sender)
        ;; )
        
        (map-set participant-status 
            {lottery-id: (var-get current-lottery-id), participant: tx-sender}
            true
        )
        
        (map-set lotteries (var-get current-lottery-id)
            (merge lottery {
                total-pool: (+ (get total-pool lottery) fee),
                participant-count: (+ (get participant-count lottery) u1)
            })
        )
        
        (ok true)
    )
)
(define-public (end-lottery)
    (let (
        (lottery (unwrap! (get-lottery-info) err-no-active-lottery))
        (participants (unwrap! (get-all-participants) err-no-active-lottery))
        (winner-index (generate-random-number stacks-block-height))
        (winner (element-at participants winner-index))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (var-get active-lottery) err-no-active-lottery)
        (asserts! (>= stacks-block-height (get end-block lottery)) err-lottery-in-progress)
        
        (match winner winner-principal
            (begin
                (try! (as-contract (stx-transfer? (get total-pool lottery) tx-sender winner-principal)))
                (map-set lotteries (var-get current-lottery-id)
                    (merge lottery {winner: (some winner-principal)})
                )
                (var-set active-lottery false)
                (ok true)
            )
            err-no-active-lottery
        )
    )
)

(define-public (emergency-stop)
    (let ((lottery (unwrap! (get-lottery-info) err-no-active-lottery)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (var-get active-lottery) err-no-active-lottery)
        
        (var-set active-lottery false)
        (ok true)
    )
)