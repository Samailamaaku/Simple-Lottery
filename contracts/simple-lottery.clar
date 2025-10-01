(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-no-active-lottery (err u101))
(define-constant err-already-participating (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-lottery-in-progress (err u104))
(define-constant err-lottery-expired (err u105))
(define-constant err-insufficient-participants (err u106))
(define-constant operator-fee-percentage u5)
(define-constant first-place-percentage u70)
(define-constant second-place-percentage u20)
(define-constant third-place-percentage u10)

(define-data-var current-lottery-id uint u0)
(define-data-var active-lottery bool false)
(define-data-var operator-fees-collected uint u0)

(define-map lotteries uint {
    entry-fee: uint,
    end-block: uint,
    total-pool: uint,
    winner: (optional principal),
    participant-count: uint,
    minimum-participants: uint,
    second-place: (optional principal),
    third-place: (optional principal)
})

(define-map lottery-participants uint (list 50 principal))
(define-map participant-status {lottery-id: uint, participant: principal} bool)
(define-map participant-stats principal {
    total-entries: uint,
    total-spent: uint,
    total-wins: uint,
    total-prize-money: uint,
    first-place-wins: uint,
    second-place-wins: uint,
    third-place-wins: uint
})

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

(define-read-only (can-claim-refund (user principal))
    (let (
        (lottery (map-get? lotteries (var-get current-lottery-id)))
        (is-participating (is-participant user))
    )
        (match lottery lottery-data
            (and 
                is-participating
                (not (var-get active-lottery))
                (< (get participant-count lottery-data) (get minimum-participants lottery-data))
                (>= stacks-block-height (get end-block lottery-data))
            )
            false
        )
    )
)

(define-read-only (get-operator-fees)
    (var-get operator-fees-collected)
)

(define-read-only (get-lottery-winners (id uint))
    (let ((lottery (map-get? lotteries id)))
        (match lottery lottery-data
            (some {
                first-place: (get winner lottery-data),
                second-place: (get second-place lottery-data),
                third-place: (get third-place lottery-data)
            })
            none
        )
    )
)

(define-read-only (get-participant-stats (user principal))
    (default-to 
        {
            total-entries: u0,
            total-spent: u0,
            total-wins: u0,
            total-prize-money: u0,
            first-place-wins: u0,
            second-place-wins: u0,
            third-place-wins: u0
        }
        (map-get? participant-stats user)
    )
)

(define-private (update-participant-entry (participant principal) (amount uint))
    (let (
        (current-stats (get-participant-stats participant))
    )
        (map-set participant-stats participant {
            total-entries: (+ (get total-entries current-stats) u1),
            total-spent: (+ (get total-spent current-stats) amount),
            total-wins: (get total-wins current-stats),
            total-prize-money: (get total-prize-money current-stats),
            first-place-wins: (get first-place-wins current-stats),
            second-place-wins: (get second-place-wins current-stats),
            third-place-wins: (get third-place-wins current-stats)
        })
        true
    )
)

(define-private (update-participant-win (participant principal) (prize-amount uint) (position uint))
    (let (
        (current-stats (get-participant-stats participant))
    )
        (map-set participant-stats participant {
            total-entries: (get total-entries current-stats),
            total-spent: (get total-spent current-stats),
            total-wins: (+ (get total-wins current-stats) u1),
            total-prize-money: (+ (get total-prize-money current-stats) prize-amount),
            first-place-wins: (if (is-eq position u1) (+ (get first-place-wins current-stats) u1) (get first-place-wins current-stats)),
            second-place-wins: (if (is-eq position u2) (+ (get second-place-wins current-stats) u1) (get second-place-wins current-stats)),
            third-place-wins: (if (is-eq position u3) (+ (get third-place-wins current-stats) u1) (get third-place-wins current-stats))
        })
        true
    )
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

(define-public (start-lottery (fee uint) (duration uint) (min-participants uint))
    (let ((lottery-id (+ (var-get current-lottery-id) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (var-get active-lottery)) err-lottery-in-progress)
        (asserts! (> fee u0) err-insufficient-funds)
        (asserts! (> min-participants u0) err-insufficient-participants)

        (map-set lotteries lottery-id {
            entry-fee: fee,
            end-block: (+ stacks-block-height duration),
            total-pool: u0,
            winner: none,
            participant-count: u0,
            minimum-participants: min-participants,
            second-place: none,
            third-place: none
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

        (update-participant-entry tx-sender fee)

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
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (var-get active-lottery) err-no-active-lottery)
        (asserts! (>= stacks-block-height (get end-block lottery)) err-lottery-in-progress)

        (if (< (get participant-count lottery) (get minimum-participants lottery))
            (begin
                (var-set active-lottery false)
                (ok false)
            )
            (let (
                (total-pool (get total-pool lottery))
                (operator-fee (/ (* total-pool operator-fee-percentage) u100))
                (prize-pool (- total-pool operator-fee))
                (first-prize (/ (* prize-pool first-place-percentage) u100))
                (second-prize (/ (* prize-pool second-place-percentage) u100))
                (third-prize (/ (* prize-pool third-place-percentage) u100))
                (participant-count (get participant-count lottery))
            )
                (if (>= participant-count u3)
                    (let (
                        (winner-index-1 (generate-random-number (+ stacks-block-height u1)))
                        (winner-index-2 (generate-random-number (+ stacks-block-height u2)))
                        (winner-index-3 (generate-random-number (+ stacks-block-height u3)))
                        (first-winner (element-at participants winner-index-1))
                        (second-winner (element-at participants (if (is-eq winner-index-2 winner-index-1) (mod (+ winner-index-2 u1) participant-count) winner-index-2)))
                        (third-winner (element-at participants (let ((adjusted-index (if (or (is-eq winner-index-3 winner-index-1) (is-eq winner-index-3 winner-index-2)) (mod (+ winner-index-3 u2) participant-count) winner-index-3))) adjusted-index)))
                    )
                        (match first-winner first-principal
                            (match second-winner second-principal
                                (match third-winner third-principal
                                    (begin
                                        (try! (as-contract (stx-transfer? first-prize tx-sender first-principal)))
                                        (try! (as-contract (stx-transfer? second-prize tx-sender second-principal)))
                                        (try! (as-contract (stx-transfer? third-prize tx-sender third-principal)))
                                        (update-participant-win first-principal first-prize u1)
                                        (update-participant-win second-principal second-prize u2)
                                        (update-participant-win third-principal third-prize u3)
                                        (var-set operator-fees-collected (+ (var-get operator-fees-collected) operator-fee))
                                        (map-set lotteries (var-get current-lottery-id)
                                            (merge lottery {
                                                winner: (some first-principal),
                                                second-place: (some second-principal),
                                                third-place: (some third-principal)
                                            })
                                        )
                                        (var-set active-lottery false)
                                        (ok true)
                                    )
                                    err-no-active-lottery
                                )
                                err-no-active-lottery
                            )
                            err-no-active-lottery
                        )
                    )
                    (let (
                        (winner-index (generate-random-number stacks-block-height))
                        (winner (element-at participants winner-index))
                    )
                        (match winner winner-principal
                            (begin
                                (try! (as-contract (stx-transfer? prize-pool tx-sender winner-principal)))
                                (update-participant-win winner-principal prize-pool u1)
                                (var-set operator-fees-collected (+ (var-get operator-fees-collected) operator-fee))
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
            )
        )
    )
)

(define-public (claim-refund)
    (let (
        (lottery (unwrap! (get-lottery-info) err-no-active-lottery))
        (is-participating (is-participant tx-sender))
    )
        (asserts! is-participating err-already-participating)
        (asserts! (not (var-get active-lottery)) err-lottery-in-progress)
        (asserts! (< (get participant-count lottery) (get minimum-participants lottery)) err-insufficient-participants)
        (asserts! (>= stacks-block-height (get end-block lottery)) err-lottery-in-progress)

        (try! (as-contract (stx-transfer? (get entry-fee lottery) tx-sender tx-sender)))
        
        (map-set participant-status 
            {lottery-id: (var-get current-lottery-id), participant: tx-sender}
            false
        )
        
        (ok true)
    )
)

(define-public (withdraw-operator-fees)
    (let ((available-fees (var-get operator-fees-collected)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> available-fees u0) err-insufficient-funds)

        (try! (as-contract (stx-transfer? available-fees tx-sender contract-owner)))
        (var-set operator-fees-collected u0)
        (ok available-fees)
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