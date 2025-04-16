#lang racket

(require racket/tcp
         racket/port
         net/url
         net/uri-codec
         racket/string
         racket/random)

;; Surprise list (you can expand this!)
(define surprises
  '("🎉 You’re awesome!"
    "🎁 A surprise is just around the corner!"
    "😂 Why don’t skeletons fight each other? They don’t have the guts."
    "🧠 Fun Fact: Octopuses have 3 hearts."
    "🌟 You have a secret talent... waiting to be discovered!"
    "🕵️ You found the hidden surprise!"
    "🍀 Today might be your lucky day!"
    "📚 The more you learn, the more magical the world becomes."
    "🚀 You're going places — just don't forget your space helmet!"
    "🎨 Create something today, even if it's just doodles."))

(define css-style "
  <style>
    body {
      font-family: 'Segoe UI', sans-serif;
      background: #f9f9f9;
      display: flex;
      flex-direction: column;
      align-items: center;
      margin: 0;
      padding: 3rem;
    }
    h1 {
      color: #2c3e50;
    }
    form {
      background: #fff;
      padding: 2rem;
      border-radius: 12px;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
      text-align: center;
    }
    input[type='submit'] {
      background: #e91e63;
      color: white;
      padding: 0.8rem 1.5rem;
      font-size: 1rem;
      border: none;
      border-radius: 8px;
      cursor: pointer;
    }
    input[type='submit']:hover {
      background: #c2185b;
    }
    .surprise {
      margin-top: 2rem;
      font-size: 1.5rem;
      color: #34495e;
      padding: 1rem 2rem;
      background: #ecf0f1;
      border-left: 6px solid #e91e63;
      border-radius: 10px;
    }
    a {
      display: inline-block;
      margin-top: 1rem;
      color: #3498db;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
")

;; Parse request line
(define (parse-request-line line)
  (define parts (string-split line " "))
  (if (>= (length parts) 2)
      (let* ([raw-url (second parts)]
             [url-obj (string->url raw-url)]
             [path (map path/param-path (url-path url-obj))])
        path)
      '()))

;; Route logic
(define (route path)
  (cond
    [(equal? path '("surprise"))
     (string-append
      "<h1>Welcome to the Surprise Generator 🎁</h1>"
      "<form action='/reveal' method='get'>
         <input type='submit' value='Give me a surprise!'>
       </form>")]

    [(equal? path '("reveal"))
     (define chosen (list-ref surprises (random (length surprises))))
     (string-append
      "<h1>🎊 Surprise! 🎊</h1>"
      (format "<div class='surprise'>~a</div>" chosen)
      "<a href='/reveal'>🔄 Get another one</a><br>"
      "<a href='/surprise'>🏠 Back to Home</a>")]

    [else
     "<h1>404 Not Found</h1><p>Try <a href='/surprise'>Surprise Generator</a></p>"]))

;; Handle client connection
(define (handle-client in out)
  (define request-line (read-line in 'any))
  (printf "Request: ~a\n" request-line)

  ;; Skip headers
  (let loop ()
    (define line (read-line in 'any))
    (unless (equal? line "")
      (loop)))

  ;; Parse and route
  (define path (parse-request-line request-line))
  (define body (route path))

  ;; Send response
  (display
   (string-append
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/html\r\n\r\n"
    "<html><head><meta charset='UTF-8'>" css-style "</head><body>"
    body
    "</body></html>")
   out)
  (flush-output out))

;; Start the server
(define listener (tcp-listen 8080))
(printf "🎁 Surprise Generator running at: http://localhost:8080/surprise\n")

(define (serve-forever)
  (let loop ()
    (define-values (in out) (tcp-accept listener))
    (thread (lambda ()
              (handle-client in out)
              (close-input-port in)
              (close-output-port out)))
    (loop)))

(serve-forever)
