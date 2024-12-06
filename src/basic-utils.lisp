(in-package :lqn)

(declaim (inline symb mkstr subx? isubx?))

(defmacro noop (&rest rest) (declare (ignore rest)) "do nothing. return nil." nil)
(defmacro pretty-json (v) `(lqn:out (lqn:jsnstr ,v :indent t)))
(defmacro lit (a) `(progn ,a))
(defmacro qt (a) `(progn ',a))

(defun clmp (v &optional (a 0.0) (b 1.0))
  (declare (number v a b)) "clamp to range (a b)."
  (max a (min v b)))

(defun lpad-lst (n lst) "left pad list." (concatenate 'list (loop repeat (- n (length lst)) collect nil) lst))
(defun rpad-lst (n lst) "right pad list." (concatenate 'list lst (loop repeat (- n (length lst)) collect nil)))

(defun group (n l) (declare (list l) (fixnum n)) "group l into lists of n elements."
  (if (< n 1) (error "group: group size is smaller than 1"))
  (labels ((rec (l acc) (let ((rest (nthcdr n l)))
                          (if (consp rest) (rec rest (cons (subseq l 0 n) acc))
                                           (nreverse (cons l acc))))))
    (if l (rec l nil) nil)))
(defun mkstr (&rest args) (declare #.*opt*) "coerce all arguments to a string."
  (with-output-to-string (s) (dolist (a args) (prtcomp (princ a s)))))
(defun kw (s) (declare #.*opt*) "mkstr, upcase, keyword."
  (intern (string-upcase (etypecase s (string s) (symbol (symbol-name s)) (number (mkstr s))))
          :keyword))
(defun ct/kw/str (a) (declare #.*opt*)
  (typecase a (string a) (keyword (string-downcase (mkstr a))) (otherwise a)))
(defun symb (&rest args) "mkstr, make symbol." (values (intern (sup (apply #'mkstr args)))))
(defun psymb (&optional (pkg 'lqn) &rest args) ;https://gist.github.com/lispm/6ed292af4118077b140df5d1012ca646
  "mkstr, make symbol in pkg."
  (values (intern (sup (apply #'mkstr args)) pkg)))
(defun lst (&rest rest) (apply #'list rest)) ; TODO: this collides with eg. veq:lst. check packages when overriding with internal symbol?

(defmacro car- (fx d) (declare (symbol d)) `(and (listp ,d) (,fx (car ,d))))
(defun sym-mode? (d &aux (mode-sym (unpack-mode d nil)))
  (if mode-sym (values-list (unpack-mode mode-sym d :?)) (values nil d)))
(defun qop? (s d &aux (d (and (listp d) (car d)))) (and d (ssym? d) (eq s (kw d))))
(defun dat?    (d) (and (symbolp d)    (eq (kw d) :_)))
; TODO: make this test better to avoid eg. veq:lst collision
(defun lqnfx?  (d) (and (ssym? d) (member (kw d) *fxns* :test #'eq)))
(defun custom-modifier? (m d)
  (and (symbolp d) (pref? (symbol-name d) m)
       (> (length (symbol-name d)) (length m))))

; IS TYPE?
(defun flt?  (f &optional d) (declare #.*opt*) "f if float; or d"
  (typecase f (double-float (coerce f 'single-float)) (single-float f) (otherwise d)))
(defun int?  (i &optional d) (declare #.*opt*) "i if int; or d"
  (typecase i (integer (coerce i 'fixnum)) (fixnum i) (otherwise d)))

; TODO: rename kv function!
(defun kv? (k &optional d) (declare #.*opt*) "k if ht; or d"
  (typecase k (hash-table k) (otherwise d)))
(defun kw? (k &optional d) (declare #.*opt*) "k if kw; or d"
  (typecase k (keyword k) (otherwise d)))
(defun sym? (s &optional d) (declare #.*opt*) "s if sym; or d"
  (typecase s (symbol s) (otherwise d)))
(defun ssym? (s &optional d) (declare #.*opt*) "s if sym, not kw; or d"
  (if (and (sym? s) (not (kw? s))) s d))

(defun num? (n &optional d) (declare #.*opt*) "n if number; or d"
  (typecase n (number n) (otherwise d)))
(defun str? (s &optional d) (declare #.*opt*) "s if string; or d"
  (typecase s (string s) (otherwise d)))
(defun vec? (v &optional d) (declare #.*opt*) "v if vector; or d"
  (typecase v (vector v) (otherwise d)))
(defun lst? (l &optional d) (declare #.*opt*) "l if list; or d"
  (typecase l (list l) (otherwise d)))
(defun seq? (s &optional d) (declare #.*opt*) "s if sequence; or d"
  (typecase s (sequence s) (otherwise d)))

; PARSE AS TYPE OR DEFAULT
(defun read? (s &optional d &rest rest) (declare #.*opt*) "read from string; or d"
  (typecase s (string (apply #'read-from-string s rest)) (otherwise d)))

; this is messy, but it works (i think)
(defun int!? (i &optional d strict) (declare #.*opt*)
  "i as int if it is int or can be parsed or coerced as int; or d"
  (handler-case (or (int? i) (int? (read? i))
                    (and (not strict) (floor (or (flt? i) (flt? (read? i)) d)))
                    d)
                (error () d)))
(defun flt!? (f &optional d strict) (declare #.*opt*)
  "f as flt if it is flt or can be parsed or coerced as flt; or d"
  (handler-case (or (flt? f) (flt? (read? f))
                    (and (not strict) (coerce (or (int? f) (int? (read? f)) d) 'single-float))
                    d)
                (error () d)))

(defun num!? (n &optional d) (declare #.*opt*)
  "n as number if it is num or can be parsed as num; or d"
  (handler-case (or (num? n) (num? (read? n)) d) (error () d)))

(defun str!? (s &optional d) (declare #.*opt*)
  "s as str if it is str or can be parsed as str; or d"
  (handler-case (or (str? (read? s)) (str? s)  d) (error () d)))
; (defun vec!? (v &optional d) "v as vector if it is vec; or d"
;   (handler-case (or (vec? v) (vec? (read? v)) d) (error () d)))
; (defun seq!? (s &optional d) "s as seq if it can be parsed; or d"
;   (handler-case (or (seq? s) (seq? (read? s)) d) (error () d)))
(defun lst!? (l &optional d) (declare #.*opt*) "v as list if it can be a list; or d"
  (labels ((cnv (a) (when (vec? a) (coerce a 'list))))
    (handler-case (or (cnv l) (cnv (read? l)) d) (error () d))))

; COERCE TO TYPE
(defun sym! (&rest rest) (declare #.*opt*) "stringify, make symbol" (apply #'symb rest))
(defun kw! (&rest rest) (declare #.*opt*) "stringify, make keyword" (apply #'psymb :keyword rest))
(defun str! (&rest rest) (declare #.*opt*) "coerce to string"
  (apply #'mkstr (loop for s in rest collect (typecase s (string s) (symbol (string-downcase s)) (t (mkstr s))))))
(defun vec! (v) (declare #.*opt*) "coerce v to vector. if v is not a string, vector"
  (typecase v (vector v) (list (coerce v 'vector)) ; this is a bit silly
              (otherwise (error "unable to force ~a to vec" v))))
(defun int! (i) (declare #.*opt*) "i as int; or fail." ; NOTE: remember to use strict
  (or (int!? i nil t) (error "unable to force ~a to int" i)))
(defun flt! (f) (declare #.*opt*) "f as float; or fail." ; strict!
  (or (flt!? f nil t) (error "unable to force ~a to float" f)))

(defun lst! (l) (declare #.*opt*) "coerce l to list if l" ; TODO: make ensure list/vec with default
  (typecase l (list l) (vector (coerce l 'list))
              (t (error "unable to coerce ~a to list" l))))

(defun size? (l &optional d) "length of sequence/number of keys in ht."
  (typecase l (sequence (length l)) (hash-table (hash-table-count l)) (otherwise d)))
(defun empty? (l &optional d &aux (n (size? l))) "t if l is empty; or d"
  (if (int? n) (< n 1) d))

(defun uniq (s &optional (fx #'equal)) (declare (function fx)) "remove duplicates from sequence"
  (remove-duplicates s :test fx))

; TODO: extend to check hts?
(defun all? (v &optional empty) (declare (sequence v)) "check if all; or empty."
  (if (empty? v) empty (loop for k across (vec? v) always (is? k))))
(defun none? (v &optional (empty t)) (declare (sequence v)) "check if none; or empty."
  (if (empty? v) empty (loop for k across (vec? v) never (is? k))))
(defun some? (v &optional empty) (declare (sequence v)) "check if some; or empty."
  (if (empty? v) empty (not (none? v))))

(defmacro smth? (v &body body) ; TODO: recursive strip with ext function
  (declare (symbol v)) "do body if v is not nil, empty sequence, or empty hash-table"
  (awg (v*)
  `(let ((,v* ,v))
     (typecase ,v* (sequence (when (> (length ,v) 0) (progn ,@body)))
                   (hash-table (when (> (hash-table-count ,v) 0) (progn ,@body)))
                   (otherwise (when ,v (progn ,@body)))))))
(defun is? (k &optional d) "k if k is not nil, empty sequence, or empty hash-table; or d"
  (if (smth? k t) k d))

(defun gk (conf k &optional silent &aux (hit (cdr (assoc k conf))))
  (declare (list conf) (keyword k)) "get k from config"
  (if (or silent hit) hit (warn "LQN: missing conf key: ~a~%conf: ~s" k conf)))

