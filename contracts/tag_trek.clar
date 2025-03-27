;; TagTrek Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-game (err u101))
(define-constant err-invalid-checkpoint (err u102))
(define-constant err-game-not-started (err u103))
(define-constant err-checkpoint-completed (err u104))
(define-constant err-invalid-location (err u105))

;; Data structures
(define-map games 
  { game-id: uint }
  { name: (string-ascii 50),
    checkpoint-count: uint,
    total-points: uint,
    active: bool })

(define-map checkpoints
  { game-id: uint, checkpoint-id: uint }
  { clue: (string-ascii 200),
    hint: (string-ascii 200),
    latitude: uint,
    longitude: uint,
    points: uint,
    proximity-radius: uint })

(define-map team-progress
  { game-id: uint, team: principal }
  { started: bool,
    completed-checkpoints: (list 20 uint),
    points: uint })

;; Administrative functions
(define-public (create-game (name (string-ascii 50)) (checkpoint-count uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set games 
        { game-id: (get-next-game-id) }
        { name: name,
          checkpoint-count: checkpoint-count,
          total-points: u0,
          active: true })
      (ok true))
    err-owner-only))

(define-public (add-checkpoint 
  (game-id uint) 
  (clue (string-ascii 200))
  (hint (string-ascii 200))
  (latitude uint)
  (longitude uint)
  (points uint))
  (if (is-eq tx-sender contract-owner)
    (let ((game (get-game game-id)))
      (if (is-some game)
        (begin
          (map-set checkpoints
            { game-id: game-id,
              checkpoint-id: (get-next-checkpoint-id game-id) }
            { clue: clue,
              hint: hint,
              latitude: latitude,
              longitude: longitude,
              points: points,
              proximity-radius: u100 })
          (ok true))
        err-invalid-game))
    err-owner-only))

;; Game play functions
(define-public (start-game (game-id uint) (team principal))
  (let ((game (get-game game-id)))
    (if (is-some game)
      (begin
        (map-set team-progress
          { game-id: game-id, team: team }
          { started: true,
            completed-checkpoints: (list),
            points: u0 })
        (ok true))
      err-invalid-game)))

(define-public (complete-checkpoint 
  (game-id uint) 
  (checkpoint-id uint)
  (latitude uint)
  (longitude uint))
  (let ((progress (get-team-progress game-id tx-sender))
        (checkpoint (get-checkpoint game-id checkpoint-id)))
    (asserts! (is-some progress) err-game-not-started)
    (asserts! (is-some checkpoint) err-invalid-checkpoint)
    (asserts! (is-valid-location latitude longitude 
      (get latitude (unwrap! checkpoint err-invalid-checkpoint))
      (get longitude (unwrap! checkpoint err-invalid-checkpoint))
      (get proximity-radius (unwrap! checkpoint err-invalid-checkpoint))) 
      err-invalid-location)
    (ok (add-completed-checkpoint game-id checkpoint-id tx-sender))))

;; Helper functions
(define-private (get-next-game-id)
  (default-to u1 (get-last-game-id)))

(define-private (get-next-checkpoint-id (game-id uint))
  (+ u1 (len (get-game-checkpoints game-id))))

(define-private (is-valid-location 
  (user-lat uint) 
  (user-long uint)
  (check-lat uint)
  (check-long uint)
  (radius uint))
  (let ((distance (calculate-distance user-lat user-long check-lat check-long)))
    (<= distance radius)))

(define-read-only (get-game (game-id uint))
  (map-get? games { game-id: game-id }))

(define-read-only (get-checkpoint (game-id uint) (checkpoint-id uint))
  (map-get? checkpoints { game-id: game-id, checkpoint-id: checkpoint-id }))

(define-read-only (get-team-progress (game-id uint) (team principal))
  (map-get? team-progress { game-id: game-id, team: team }))
