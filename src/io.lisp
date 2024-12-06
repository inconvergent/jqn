(in-package #:lqn)
; YASON DOCS https://phmarek.github.io/yason/
; (setf (readtable-case *readtable*) :preserve)

(defun read-all-str (s &aux (pos 0)) (declare #.*opt*)
  (loop for (l new-pos) = (mvl (read-from-string s nil 'lqn::eof :start pos))
        while (not (eq l 'lqn::eof)) do (setf pos new-pos) collect l))

(defun txt-read-stream (&optional (s *standard-input*) &aux (res (make-adjustable-vector)))
  (declare #.*opt*) "read lines of text from stream into vector."
  (loop for l = (read-line s nil nil) while l do (vex res l))
  res)
(defun txt-read-file (fn &aux (res (make-adjustable-vector)))
  (declare #.*opt*) "read lines of text from file into vector."
  (with-open-file (in fn)
    (loop for l = (read-line in nil nil) while l do (vex res l)))
  res)
(defun txt-export (fn v &optional (pfx ".txt"))
  (declare #.*opt* (string fn pfx) (vector v))
  "write lines from vector to file. see txt-read-file"
  (with-open-file (f (mkstr fn pfx) :direction :output :if-exists :supersede)
    (loop for l across v do (format f "~&~a~%" l)) nil))

(defun dat-read-one (fn)
  (declare #.*opt*) "read lisp one object from file. see dat-export."
  (with-open-file (in fn) (read in nil nil)))
(defun dat-read-file (fn &aux (res (mav)))
  (declare #.*opt*) "read lisp data from file into vector. see dat-export."
  (with-open-file (in fn)
    (loop for l = (read in nil nil) while l do (vex res l)))
  res)
(defun dat-read-stream (s &aux (res (mav)))
  (declare #.*opt*) "read lisp data from stream into vector."
  (loop for l = (read s nil nil) while l do (vex res l))
  res)
(defun dat-export (fn o &optional (pfx ".dat"))
  (declare #.*opt* (string fn pfx)) "write o to file. see dat-read-file"
  (with-open-file (f (mkstr fn pfx) :direction :output :if-exists :supersede)
    (format f "~s~%" o) nil))

(defun jsnloads (&optional (s *standard-input*) all)
  (declare #.*opt*) "parse json from stream; or *standard-input*"
  (let ((yason:*parse-json-arrays-as-vectors* t))
    (if all (let ((res (mav)))
              (handler-case (loop for j = (yason:parse s) while j
                                  do (vex res j) finally (return res))
                (end-of-file () res)))
            (yason:parse s))))
(defun jsnloadf (fn) (declare #.*opt* (string fn)) "parse json from file, fn"
  (with-open-file (f fn :direction :input)
    (handler-case (jsnloads f) (end-of-file () (warn "empty file: ~a" fn)))))

(defun jsnout (o &key (s *standard-output*) indent)
  (declare #.*opt* (stream s) (boolean indent))
  "stream serialized json from o to s; or *standard-output*"
  (let ((yason:*symbol-key-encoder* 'yason:encode-symbol-as-lowercase)
        (yason:*symbol-encoder* 'yason:encode-symbol-as-lowercase)
        (yason:*list-encoder* 'yason:encode-alist))
    (format s "~&")
    (yason:encode o (yason:make-json-output-stream s :indent indent))
    (format s "~&")
    (finish-output s)))
(defun jsnstr (o &key indent (s (make-string-output-stream)))
  (declare (boolean indent)) "serialize o as json to string"
  (jsnout o :s s :indent indent)
  (get-output-stream-string s))

; TODO: character keys are probably not compatible with the internal json representation?
; TODO: is this consistent with JSON representation in general?
(defun ldnout (o) "serialize internal representation to readable lisp data.
most notably lists and vectors are serialized as #(..), and hash-tables are serialized
as alists. see ldnload."
  ; TODO: there is/was a recursion stack overflow here for large lists (in
  ; particular) and when flattening hash-tables can we do this in a smarter
  ; way?
  (labels ((ldnkey (k) (typecase k (number k) (string (kw k)) (sequence k)
                                   (character k) (otherwise (kw k)))))
   (typecase o (string o)
                 ; simplistic alist test
     (cons (cond ((consp (cdr o)) (map 'list (lambda (k) (ldnout k)) o))
                 ; map appears to behave better than loop+collect and (cons car cdr)?
                 (t (cons (ldnout (car o)) (ldnout (cdr o))))))
     ; (cons (cons (ldnout (car o)) (ldnout (cdr o))))
     (hash-table (loop for k being the hash-keys of o using (hash-value v)
                       collect `(,(ldnkey k) . ,(ldnout v))))
     (vector (loop with res = (make-adjustable-vector)
                   for v across o do (vex res (ldnout v))
                   finally (return res)))
     (otherwise o))))
(defun ldnload (o) "read serialized data. reverse of ldnout."
  (labels ((ldnkey (k) (typecase k (keyword (sdwn (str! k))) (number k) (string (kw k))
                                   (sequence k) (character k) (otherwise (kw k)))))
   (typecase o (string o) (character o)
              (vector (map 'vector #'ldnload o))
              (list (loop with res = (make-hash-table :test #'equal)
                          for (k . v) in o do (setf (gethash (ldnkey k) res) (ldnload v))
                          finally (return res)))
              (otherwise o))))

(defmacro out (s &rest rest) "print to standard out"
  (awg (s*) (if rest `(format *standard-output* ,s ,@rest)
                     `(let ((,s* ,s))
                        (when (and ,s* (or (not (stringp ,s*)) (> (length ,s*) 0)))
                          (format *standard-output* "~&~a~&" ,s*))))))
(defmacro fmt (s &rest rest) "format to string."
  (if rest `(format nil ,s ,@rest) `(format nil "~a" ,s)))
(defmacro stdstr (&body body) "trap stdout as string."
  `(with-output-to-string (*standard-output*) ,@body))

(defun nstr (n &optional (c #\Space)) "str of length n, filled with c"
  (make-string n :initial-element c))
(defun lpad (s n &optional (c #\Space))
  (declare (string s) (fixnum n)) "left pad to length n. always of length n."
  (let ((d (- n (length s))))
    (cond ((< d 0) (subseq s (abs d))) ((> d 0) (strcat (nstr d c) s)) (t s))))
(defun rpad (s n &optional (c #\Space) &aux (l (length s)))
  (declare (string s) (fixnum n)) "right pad to length n. always of length n."
  (let ((d (- n l)))
    (cond ((< d 0) (subseq s 0 (+ l d))) ((> d 0) (strcat s (nstr d c))) (t s))))

(defun bar (size s &optional (pad #\Space) (bbb " ▏▎▍▌▋▊▉█") &aux (l (length bbb)))
  (declare (fixnum size) (float s)) "draw progress bar"
  (labels ((pad? (res) (if pad (rpad res size pad) res)))
    (when (<= s 0.0) (return-from bar (pad? "")))
    (let* ((i* (* (max 0.0 (clmp s)) size))
           (full (floor i*))
           (part (mod (floor (* l (rem i* 1))) l))
           (res (strcat (nstr full (char bbb (1- l))) (char bbb part))))
      (pad? res))))
(defun ascii (s) (declare (float s))"ascii char with this density."
  (let ((chars " `.-':_,^=;><+!rc*/z?sLTv)J7(|Fi{C}fI31tlu[neoZ5Yxjya]2ESwqkP6h9d4VpOGbUAKXHm8RD#$Bg0MNWQ%&@")
        (dens #(0 0.0751 0.0829 0.0848 0.1227 0.1403 0.1559 0.185 0.2183 0.2417
                  0.2571 0.2852 0.2902 0.2919 0.3099 0.3192 0.3232 0.3294
                  0.3384 0.3609 0.3619 0.3667 0.3737 0.3747 0.3838 0.3921 0.396
                  0.3984 0.3993 0.4075 0.4091 0.4101 0.42 0.423 0.4247 0.4274
                  0.4293 0.4328 0.4382 0.4385 0.442 0.4473 0.4477 0.4503 0.4562
                  0.458 0.461 0.4638 0.4667 0.4686 0.4693 0.4703 0.4833 0.4881
                  0.4944 0.4953 0.4992 0.5509 0.5567 0.5569 0.5591 0.5602
                  0.5602 0.565 0.5776 0.5777 0.5818 0.587 0.5972 0.5999 0.6043
                  0.6049 0.6093 0.6099 0.6465 0.6561 0.6595 0.6631 0.6714
                  0.6759 0.6809 0.6816 0.6925 0.7039 0.7086 0.7235 0.7302
                  0.7332 0.7602 0.7834 0.8037 0.9999)))
    (loop with s = (clmp s) for i from 0 for v across dens
          if (>= v s) do (return-from ascii (aref chars i)))
    (@get chars -1 nil)))

