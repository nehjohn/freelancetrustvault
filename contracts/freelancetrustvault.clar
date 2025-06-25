;; FreelanceEscrowPlus - Enhanced Freelance Escrow Contract

;; Contract Constants & Error Codes
(define-constant ADMINISTRATOR tx-sender)
(define-constant ERROR_NOT_AUTHORIZED (err u200))
(define-constant ERROR_ESCROW_MISSING (err u201))
(define-constant ERROR_ALREADY_PROCESSED (err u202))
(define-constant ERROR_TRANSACTION_FAILED (err u203))
(define-constant ERROR_INVALID_IDENTIFIER (err u204))
(define-constant ERROR_INVALID_SUM (err u205))
(define-constant ERROR_UNQUALIFIED_FREELANCER (err u206))
(define-constant ERROR_DEADLINE_PASSED (err u207))
(define-constant ESCROW_DURATION u1008) ;; ~7 days worth of blocks

;; Storage: Mapping Escrow Transactions
(define-map EscrowRecords
  { transaction-id: uint }
  {
    client-addr: principal,
    freelancer-addr: principal,
    total-funds: uint,
    milestone-funds: uint,
    escrow-status: (string-ascii 10),
    created-at: uint,
    expiry-at: uint
  }
)

(define-map FreelancerRatings
  principal
  uint
)

(define-map FreelancerFeedback
  { freelancer: principal, transaction-id: uint }
  (string-ascii 128)
)

(define-data-var latest-escrow-id uint u0)

;; Private Validation Functions
(define-private (is-eligible-freelancer (freelancer principal))
  (and 
    (not (is-eq freelancer tx-sender))
    (not (is-eq freelancer (as-contract tx-sender)))
  )
)

(define-private (is-valid-transaction-id (transaction-id uint))
  (<= transaction-id (var-get latest-escrow-id))
)

;; Public Function: Initiate a New Milestone Escrow
(define-public (initialize-milestone-escrow (freelancer principal) (total-funds uint) (milestone-funds uint))
  (let
    (
      (transaction-id (+ (var-get latest-escrow-id) u1))
      (expiry-at (+ stacks-block-height ESCROW_DURATION))
    )
    (asserts! (> total-funds u0) ERROR_INVALID_SUM)
    (asserts! (> milestone-funds u0) ERROR_INVALID_SUM)
    (asserts! (<= milestone-funds total-funds) ERROR_INVALID_SUM)
    (asserts! (is-eligible-freelancer freelancer) ERROR_UNQUALIFIED_FREELANCER)
    (match (stx-transfer? milestone-funds tx-sender (as-contract tx-sender))
      success
        (begin
          (map-set EscrowRecords
            { transaction-id: transaction-id }
            {
              client-addr: tx-sender,
              freelancer-addr: freelancer,
              total-funds: total-funds,
              milestone-funds: milestone-funds,
              escrow-status: "active",
              created-at: stacks-block-height,
              expiry-at: expiry-at
            }
          )
          (var-set latest-escrow-id transaction-id)
          (ok transaction-id)
        )
      error ERROR_TRANSACTION_FAILED
    )
  )
)

;; Public Function: Release Milestone Payment
(define-public (execute-milestone-payout (transaction-id uint))
  (let
    (
      (escrow (unwrap! (map-get? EscrowRecords { transaction-id: transaction-id }) ERROR_ESCROW_MISSING))
      (freelancer (get freelancer-addr escrow))
      (milestone-funds (get milestone-funds escrow))
    )
    (asserts! (or (is-eq tx-sender ADMINISTRATOR) (is-eq tx-sender (get client-addr escrow))) ERROR_NOT_AUTHORIZED)
    (asserts! (is-eq (get escrow-status escrow) "active") ERROR_ALREADY_PROCESSED)
    (asserts! (<= stacks-block-height (get expiry-at escrow)) ERROR_DEADLINE_PASSED)
    (map-set EscrowRecords { transaction-id: transaction-id } (merge escrow { escrow-status: "paid" }))
    (match (as-contract (stx-transfer? milestone-funds tx-sender freelancer))
      success
        (ok true)
      error ERROR_TRANSACTION_FAILED
    )
  )
)

;; Public Function: Refund Client
(define-public (process-client-refund (transaction-id uint))
  (let
    (
      (escrow (unwrap! (map-get? EscrowRecords { transaction-id: transaction-id }) ERROR_ESCROW_MISSING))
      (client (get client-addr escrow))
      (milestone-funds (get milestone-funds escrow))
    )
    (asserts! (is-eq tx-sender ADMINISTRATOR) ERROR_NOT_AUTHORIZED)
    (asserts! (is-eq (get escrow-status escrow) "active") ERROR_ALREADY_PROCESSED)
    (map-set EscrowRecords { transaction-id: transaction-id } (merge escrow { escrow-status: "refunded" }))
    (match (as-contract (stx-transfer? milestone-funds tx-sender client))
      success
        (ok true)
      error ERROR_TRANSACTION_FAILED
    )
  )
)

;; Public Function: Submit Feedback
(define-public (submit-feedback (transaction-id uint) (feedback (string-ascii 128)) (rating uint))
  (let ((escrow (unwrap! (map-get? EscrowRecords { transaction-id: transaction-id }) ERROR_ESCROW_MISSING)))
    (asserts! (is-eq tx-sender (get client-addr escrow)) ERROR_NOT_AUTHORIZED)
    (map-set FreelancerFeedback { freelancer: (get freelancer-addr escrow), transaction-id: transaction-id } feedback)
    (let ((current-rating (default-to u0 (map-get? FreelancerRatings (get freelancer-addr escrow)))))
      (map-set FreelancerRatings (get freelancer-addr escrow) (+ current-rating rating))
    )
    (ok true)
  )
)

;; Read-Only Function: Retrieve Escrow Information
(define-read-only (fetch-escrow-info (transaction-id uint))
  (match (map-get? EscrowRecords { transaction-id: transaction-id })
    escrow (ok escrow)
    ERROR_ESCROW_MISSING
  )
)

;; Read-Only Function: Get Freelancer Rating
(define-read-only (get-freelancer-rating (freelancer principal))
  (ok (default-to u0 (map-get? FreelancerRatings freelancer)))
)

;; Read-Only Function: Get Freelancer Feedback
(define-read-only (get-freelancer-feedback (freelancer principal) (transaction-id uint))
  (map-get? FreelancerFeedback { freelancer: freelancer, transaction-id: transaction-id })
)

;; Read-Only Function: Get Latest Escrow ID
(define-read-only (fetch-latest-transaction-id)
  (ok (var-get latest-escrow-id))
)
