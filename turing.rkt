#lang racket
(define step 10000)

(define (create-tape)
 (define (_ ret)
  (let ((x (read)))
   (if (eof-object? x)
    ret
    (_ (cons x ret)))))
 (list->vector (reverse (_ '()))))

(define (create-turing rule-file)
 (define (make-init-matrix m n)
  (define (set v)
   (define (_ pos)
    (if (>= pos m)
     (void)
     (begin
      (vector-set! v pos (make-vector n '(2 0 0)))
      (_ (+ pos 1)))))
   (_ 0))
  (let ((ret (make-vector m 0)))
   (set ret)
   ret))

 (define (_ port ret)
  (define (str->list s)
   (define (index s c)
    (define (_index s c len pos)
     (if (= pos len)
      -1
      (if (eq? c (string-ref s pos))
       pos
       (_index s c len (+ pos 1)))))
   (_index s c (string-length s) 0))
   (let* ((i (index s #\#))
 	 (s2 (if (< i 0) s (substring s 0 i)))
	 (s3 (string-split s2)))
    (if (< (length s3) 5)
     (map string->number s3)
     (let* ((no1 (lambda (s) (string-ref s 0)))
	    (nc? (lambda (c) (char<=? #\0 c #\9)))
	    (t (lambda (s) (if (nc? (no1 s)) (string->number s) #f)))
	    (t2 (lambda (s) (let ((c (no1 s)))
			     (cond
			      ((nc? c) (string->number s))
			      ((eq? c #\R) 0)
			      ((eq? c #\r) 0)
			      (else 1)))))
	    (tr (lambda (s) (append
			     (take s 2)
			     (map
			      (lambda (a b) (or a b))
			      (drop (take s 4) 2)
			      (take s 2))
			     (list (last s)))))
	    (s4 (map (lambda (s n) ((if (= n 4) t2 t) s)) s3 (range 5)))) 
      (if (second s4)
       (list (tr s4))
       (map
	(lambda (n) (tr (list-set s4 1 n)))
	(range 1 (vector-length (vector-ref ret 0)))))))))
 
  (let ((s (read-line port)))
   (if (eof-object? s)
    ret
    (let ((nums (str->list s)))
     (cond
      ((null? nums) (_ port ret))
      ((null? ret) (_ port (make-init-matrix (+ 1 (first nums)) (+ 1 (second nums)))))
      (else
       (for-each
	(lambda (nums2)
	 (vector-set! (vector-ref ret (first nums2)) (second nums2) (drop nums2 2)))
	nums)
       (_ port ret)))))))
 (let ((port (open-input-file rule-file)))
  (let ((ret (_ port '())))
   (close-input-port port)
   ret)))

(define (display-tape tape pos)
 (define (valid-length tape)
  (define (_ _max)
   (if (zero? _max)
    0
    (if (zero? (vector-ref tape (- _max 1)))
     (_ (- _max 1))
     (max _max (+ 1 pos)))))
  (_ (vector-length tape)))
 (let ((len (valid-length tape)))
  (display "ACCEPT\nTAPE:\n")
  (for-each
   (lambda (c x)
    (display
     (format
      (string-append
       (if (= pos x) "[~a]\t" "~a\t")
       (if (= 15 (remainder x 16)) "\n" ""))
      c)))
   (take (vector->list tape) len)
   (range len))
  (newline)))

(define (run-turing rules tape)
 (define (run tape stat pos)
  (cond
   ((= stat 1) (display-tape tape pos))
   ((= stat 2) (display "REJECT\n"))
   (else
    (let* ((res (vector-ref (vector-ref rules stat) (vector-ref tape pos)))
	   (new-stat (first res))
	   (new-value (second res))
	   (new-pos (if (zero? (third res)) (+ pos 1) (- pos 1))))
     (vector-set! tape pos new-value)
     (if (< new-pos 0)
      (begin
       (display "WRONG\n")
       (exit 1))
      (if (= new-pos (vector-length tape))
       (let ((new-tape (make-vector (+ step (vector-length tape)) 0)))
	(vector-copy! new-tape 0 tape)
        (run new-tape new-stat new-pos))
       (run tape new-stat new-pos)))))))
 (run tape 0 0))

(run-turing
 (create-turing (vector-ref (current-command-line-arguments) 0))
 (create-tape))
