;; Synth-Stocks: Synthetic Stock Index Trading Contract
;; A decentralized synthetic asset protocol for major stock indices

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-index (err u103))
(define-constant err-oracle-not-set (err u104))
(define-constant err-price-stale (err u105))
(define-constant err-insufficient-collateral (err u106))
(define-constant err-liquidation-threshold (err u107))

;; Data Variables
(define-data-var oracle-address (optional principal) none)
(define-data-var collateralization-ratio uint u150) ;; 150% minimum collateral
(define-data-var price-staleness-threshold uint u3600) ;; 1 hour in seconds

;; Stock Index Definitions
(define-map stock-indices 
  { index-id: uint }
  { 
    name: (string-ascii 20),
    symbol: (string-ascii 10),
    price: uint,
    last-updated: uint,
    total-supply: uint,
    is-active: bool
  }
)

;; User Positions
(define-map user-positions
  { user: principal, index-id: uint }
  {
    synthetic-tokens: uint,
    collateral-stx: uint,
    last-interaction: uint
  }
)

;; User Synthetic Token Balances
(define-map synthetic-balances
  { user: principal, index-id: uint }
  uint
)

;; Initialize stock indices
(define-private (init-indices)
  (begin
    ;; S&P 500
    (map-set stock-indices 
      { index-id: u1 }
      { 
        name: "S&P 500 Synthetic",
        symbol: "sSP500",
        price: u450000, ;; $4500.00 (scaled by 100)
        last-updated: u0,
        total-supply: u0,
        is-active: true
      }
    )
    ;; NASDAQ
    (map-set stock-indices 
      { index-id: u2 }
      { 
        name: "NASDAQ Synthetic",
        symbol: "sNASDAQ",
        price: u1500000, ;; $15000.00 (scaled by 100)
        last-updated: u0,
        total-supply: u0,
        is-active: true
      }
    )
    ;; FTSE 100
    (map-set stock-indices 
      { index-id: u3 }
      { 
        name: "FTSE 100 Synthetic",
        symbol: "sFTSE",
        price: u750000, ;; $7500.00 (scaled by 100)
        last-updated: u0,
        total-supply: u0,
        is-active: true
      }
    )
  )
)

;; Initialize the contract
(init-indices)

;; Read-only functions

;; Get stock index info
(define-read-only (get-stock-index (index-id uint))
  (map-get? stock-indices { index-id: index-id })
)

;; Get user position
(define-read-only (get-user-position (user principal) (index-id uint))
  (map-get? user-positions { user: user, index-id: index-id })
)

;; Get synthetic token balance
(define-read-only (get-synthetic-balance (user principal) (index-id uint))
  (default-to u0 (map-get? synthetic-balances { user: user, index-id: index-id }))
)

;; Calculate required collateral
(define-read-only (calculate-required-collateral (index-id uint) (token-amount uint))
  (match (get-stock-index index-id)
    index-info 
    (let ((index-price (get price index-info)))
      (ok (/ (* token-amount index-price (var-get collateralization-ratio)) u100))
    )
    (err err-invalid-index)
  )
)

;; Check if position is healthy (above liquidation threshold)
(define-read-only (is-position-healthy (user principal) (index-id uint))
  (match (get-user-position user index-id)
    position
    (match (get-stock-index index-id)
      index-info
      (let (
        (token-amount (get synthetic-tokens position))
        (collateral (get collateral-stx position))
        (index-price (get price index-info))
        (required-collateral (/ (* token-amount index-price (var-get collateralization-ratio)) u100))
      )
        (>= collateral required-collateral)
      )
      false
    )
    true ;; No position means healthy
  )
)

;; Public functions

;; Set oracle address (owner only)
(define-public (set-oracle-address (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set oracle-address (some new-oracle))
    (ok true)
  )
)

;; Update stock index price (oracle only)
(define-public (update-price (index-id uint) (new-price uint))
  (begin
    (asserts! (is-some (var-get oracle-address)) err-oracle-not-set)
    (asserts! (is-eq tx-sender (unwrap-panic (var-get oracle-address))) err-owner-only)
    
    (match (get-stock-index index-id)
      index-info
      (begin
        (map-set stock-indices 
          { index-id: index-id }
          (merge index-info { 
            price: new-price,
            last-updated: stacks-block-height
          })
        )
        (ok true)
      )
      err-invalid-index
    )
  )
)

;; Mint synthetic tokens by providing STX collateral
(define-public (mint-synthetic (index-id uint) (token-amount uint))
  (let (
    (stx-amount (stx-get-balance tx-sender))
  )
    (asserts! (> token-amount u0) err-invalid-amount)
    
    (let ((required-collateral (unwrap! (calculate-required-collateral index-id token-amount) err-invalid-index)))
      (asserts! (>= stx-amount required-collateral) err-insufficient-collateral)
      
      ;; Transfer STX as collateral
      (try! (stx-transfer? required-collateral tx-sender (as-contract tx-sender)))
      
      ;; Update user position
      (match (get-user-position tx-sender index-id)
        existing-position
        (map-set user-positions
          { user: tx-sender, index-id: index-id }
          {
            synthetic-tokens: (+ (get synthetic-tokens existing-position) token-amount),
            collateral-stx: (+ (get collateral-stx existing-position) required-collateral),
            last-interaction: stacks-block-height
          }
        )
        (map-set user-positions
          { user: tx-sender, index-id: index-id }
          {
            synthetic-tokens: token-amount,
            collateral-stx: required-collateral,
            last-interaction: stacks-block-height
          }
        )
      )
      
      ;; Update synthetic balance
      (map-set synthetic-balances
        { user: tx-sender, index-id: index-id }
        (+ (get-synthetic-balance tx-sender index-id) token-amount)
      )
      
      ;; Update total supply
      (let ((index-info (unwrap! (get-stock-index index-id) err-invalid-index)))
        (map-set stock-indices
          { index-id: index-id }
          (merge index-info { total-supply: (+ (get total-supply index-info) token-amount) })
        )
        (ok token-amount)
      )
    )
  )
)

;; Burn synthetic tokens and retrieve collateral
(define-public (burn-synthetic (index-id uint) (token-amount uint))
  (let (
    (current-balance (get-synthetic-balance tx-sender index-id))
  )
    (asserts! (> token-amount u0) err-invalid-amount)
    (asserts! (>= current-balance token-amount) err-insufficient-balance)
    
    (let (
      (position (unwrap! (get-user-position tx-sender index-id) err-insufficient-balance))
      (index-info (unwrap! (get-stock-index index-id) err-invalid-index))
      (index-price (get price index-info))
      (collateral-to-return (/ (* token-amount index-price (var-get collateralization-ratio)) u100))
      (new-synthetic-tokens (- (get synthetic-tokens position) token-amount))
      (new-collateral (- (get collateral-stx position) collateral-to-return))
    )
      ;; Update user position
      (if (is-eq new-synthetic-tokens u0)
        (map-delete user-positions { user: tx-sender, index-id: index-id })
        (map-set user-positions
          { user: tx-sender, index-id: index-id }
          {
            synthetic-tokens: new-synthetic-tokens,
            collateral-stx: new-collateral,
            last-interaction: stacks-block-height
          }
        )
      )
      
      ;; Update synthetic balance
      (map-set synthetic-balances
        { user: tx-sender, index-id: index-id }
        (- current-balance token-amount)
      )
      
      ;; Update total supply
      (map-set stock-indices
        { index-id: index-id }
        (merge index-info { total-supply: (- (get total-supply index-info) token-amount) })
      )
      
      ;; Return collateral
      (try! (as-contract (stx-transfer? collateral-to-return tx-sender tx-sender)))
      
      (ok collateral-to-return)
    )
  )
)

;; Transfer synthetic tokens between users
(define-public (transfer-synthetic (index-id uint) (amount uint) (recipient principal))
  (let (
    (sender-balance (get-synthetic-balance tx-sender index-id))
  )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    
    ;; Update sender balance
    (map-set synthetic-balances
      { user: tx-sender, index-id: index-id }
      (- sender-balance amount)
    )
    
    ;; Update recipient balance
    (map-set synthetic-balances
      { user: recipient, index-id: index-id }
      (+ (get-synthetic-balance recipient index-id) amount)
    )
    
    (ok true)
  )
)

;; Liquidate undercollateralized position
(define-public (liquidate-position (user principal) (index-id uint))
  (begin
    (asserts! (not (is-position-healthy user index-id)) err-liquidation-threshold)
    
    (let (
      (position (unwrap! (get-user-position user index-id) err-insufficient-balance))
      (synthetic-tokens (get synthetic-tokens position))
      (collateral (get collateral-stx position))
      (liquidator-reward (/ collateral u20)) ;; 5% liquidation reward
    )
      ;; Clear user position
      (map-delete user-positions { user: user, index-id: index-id })
      (map-set synthetic-balances { user: user, index-id: index-id } u0)
      
      ;; Update total supply
      (let ((index-info (unwrap! (get-stock-index index-id) err-invalid-index)))
        (map-set stock-indices
          { index-id: index-id }
          (merge index-info { total-supply: (- (get total-supply index-info) synthetic-tokens) })
        )
      )
      
      ;; Pay liquidator reward
      (try! (as-contract (stx-transfer? liquidator-reward tx-sender tx-sender)))
      
      (ok true)
    )
  )
)

;; Set collateralization ratio (owner only)
(define-public (set-collateralization-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-ratio u100) err-invalid-amount) ;; Minimum 100%
    (var-set collateralization-ratio new-ratio)
    (ok true)
  )
)