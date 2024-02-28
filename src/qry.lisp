(in-package :lqn)

(defun compile/|| (rec conf d) ; (|| ...) pipe
  (awg (∇-)
   (if (< (length d) 2) (funcall rec conf (car d))
      `(let ((,∇- ,(gk conf :dat)))
         ,@(loop for op in d collect `(setf ,∇- ,(funcall rec (dat/new conf ∇-) op)))
        ,∇-))))

(defun compile/@ (rec conf d &aux (dat (gk conf :dat)))
  (case (length d) (0 `(@@ ,dat 0 nil))
                   (1 `(@@ ,dat ,(funcall rec conf (car d))))
                   (2 `(@@ ,dat ,@(funcall rec conf d)))
                   (3 `(@@ ,@(funcall rec conf d)))
                   (otherwise (error "@: expected 0-3 arguments. got: ~a." d))))

(defun compile/?map (rec conf d) ; (?map ...)
  (when (zerop (length d)) (error "?map: missing args."))
  (awg (k i kres ires itr par)
    (labels ((err () `(error "?map/rt: bad type. expected hash-table or vector:~%got: ~a." ,par))
             (do-ht (expr) `(loop with ,kres = (new$)
                                  for ,i from 0
                                  for ,itr being the hash-values of ,par
                                                 using (hash-key ,k)
                                  do (∈ (:par ,par :cnt ,i :itr ,itr :key ,k)
                                        (setf (gethash ,k ,kres)
                                              ,(funcall rec (dat/new conf itr) expr)))
                                  finally (return ,kres)))
             (do-vec (expr) `(loop with ,ires = (mav) with ,par = (vec! ,par)
                                   for ,itr across ,par for ,i from 0
                                   do (∈ (:par ,par :cnt ,i :itr ,itr :key ,i)
                                         (vex ,ires ,(funcall rec (dat/new conf itr) expr)))
                                   finally (return ,ires)))
             (do-map (expr) `(let ((,par ,(gk conf :dat)))
                               (typecase ,par (hash-table ,(do-ht expr))
                                              (vector ,(do-vec expr))
                                              (simple-vector ,(do-vec expr))
                                              (otherwise ,(err))))))
      (let ((cd (car d)))
        (typecase cd (list (do-map cd)) (vector (do-map cd))
          (otherwise (error "?map: expected vector or cons. got: ~a." cd)))))))

(defun compile/?fld (rec conf d) ; (?fld ...)
  (awg (k i res itr par)         ; 0 + ; 0 acc (+ acc _)
    (labels ((err () `(error "?fld/rt: bad type. expected hash-table or vector:~%got: ~a." ,par))
             (do-ht (init acc itr expr)
               `(loop for ,i from 0
                      for ,itr being the hash-values of ,par using (hash-key ,k)
                      do (∈ (:par ,par :cnt ,i :key ,k :itr ,itr)
                            (setf ,acc ,(funcall rec (dat/new conf itr) expr)))))
             (do-vec (init acc itr expr)
               `(loop with ,par = (vec! ,par) ; TODO: this is redundant, and wont work for lists
                      for ,itr across ,par for ,i from 0
                      do (∈ (:par ,par :cnt ,i :key ,i :itr ,itr)
                            (setf ,acc ,(funcall rec (dat/new conf itr) expr)))))
             (do-fld (init acc itr expr)
               (unless (and (symbolp acc) (symbolp itr))
                       (error "?fld: expected symbols, got: ~a/~a." acc itr))
               (unless (consp expr) (error "?fld: expected cons or got: ~a." expr))
               `(let ((,par ,(gk conf :dat))
                      (,acc ,init))
                  (typecase ,par (hash-table ,(do-ht init acc itr expr))
                                 (vector ,(do-vec init acc itr expr))
                                 (simple-vector ,(do-vec init acc itr expr))
                                 (otherwise ,(err)))
                  ,acc)))
      (case (length d)
        (2 (etypecase (second d)
             (symbol (do-fld (car d) res itr `(,(second d) ,res ,itr)))
             (cons (do-fld (car d) res itr `(,(first (second d)) ,res ,@(cdr (second d)))))))
        (3 (let ((d3 (third d))) (do-fld (car d) (second d) itr d3)))
        (otherwise (error "?fld: expected 2-3 args. got: ~a." d))))))

(defun compile/$$ (rec conf d) ; {...} ; sel
  (awg (kres par dat)
    `(let* ((,par ,(gk conf :dat))
            (,kres ,(if (car- dat? d) `(make$ ,par) `(make$))))
       (∈ (:par ,par)
          ,@(loop for (m kk expr) in (strip-all d) collect
              `(let ((,dat (@@ ,par ,kk)))
                 (declare (ignorable ,dat))
                 (∈ (:key ,kk)
                    ,(compile/$add rec (dat/new conf dat) m kres kk expr)))))
       ($nil ,kres))))

(defun compile/$* (rec conf d) ; #[...] ; sel
  (awg (i ires itr dat par)
    `(loop with ,ires of-type vector = (mav)
           with ,par of-type vector = (vec! ,(gk conf :dat))
           for ,itr across ,par for ,i from 0
           do (∈ (:par ,par :cnt ,i :itr ,itr)
                 ,(when (car- dat? d) (compile/*add rec conf :+ ires itr))
                 ,@(loop for (m kk expr) in (strip-all d) collect
                     `(let ((,dat (@@ ,itr ,kk)))
                        (declare (ignorable ,dat))
                        (∈ (:key ,kk)
                           ,(compile/*add rec (dat/new conf dat) m ires expr)))))
           finally (return ,ires))))

(defun compile/*$ (rec conf d) ; #{...} ; sel
  (awg (i ires kvres itr dat par)
    `(loop with ,ires of-type vector = (mav)
           with ,par of-type vector = (vec! ,(gk conf :dat))
           for ,itr of-type hash-table across ,par for ,i from 0
           for ,kvres of-type hash-table = ,(if (car- dat? d) `(make$ ,itr) `(make$))
           do (∈ (:par ,par :cnt ,i :itr ,itr)
                 ,@(loop for (m kk expr) in (strip-all d)
                     collect `(let ((,dat (@@ ,itr ,kk)))
                                (declare (ignorable ,dat))
                                (∈ (:key ,kk)
                                ,(compile/$add rec (dat/new conf dat) m kvres kk expr))))
                 (vex ,ires ($nil ,kvres)))
           finally (return ,ires))))

(defun pre/** (q &optional (mm :?)) (unless q (warn "**: missing args."))
  (labels ((unpack- (o) (dsb (m sk) (unpack-mode o mm) `(,m ,(pre/xpr-sel sk :_)))))
    (let* ((q* (remove-if #'dat? (pre/scan-clauses q '#:**)))
           (res (mapcar #'unpack- q*)))
      (if (= (length q) (length q*)) res (cons :_ res)))))

(defun get-modes (cd &rest mm)
  (loop for (m expr) in (strip-all cd) if (member m mm :test #'eq) collect expr))

(defun compile/** (rec conf d) ; [...] ; sel, filter
  (awg (i ires itr par)
    `(loop with ,ires of-type vector = (mav)
           with ,par of-type vector = (vec! ,(gk conf :dat))
           for ,itr across ,par for ,i from 0
           do ,(compile/?xpr rec `((:par . ,par) (:dat . ,itr) (:cnt . ,i) (:itr . ,itr))
                 `(,@d (vex ,ires ,@(or (get-modes d :%) `(,itr))) nil))
           finally (return ,ires))))

(defun compile/?xpr/bool (rec conf cd)
  (labels ((rec (expr) (funcall rec conf expr)))
    (let ((ands (get-modes cd :+)) (nots (get-modes cd :-)) (ors (get-modes cd :?)))
      (cond ((and nots (null ands) (null ors)) (rec `(not (or ,@nots))))
            (t (rec `(and (or ,(car- dat? cd) ,@ors ,@(and ands `((and ,@ands))))
                          ,@(when nots `((not (or ,@nots)))))))))))
(defun compile/?xpr (rec conf d) ; (xpr sel .. hit miss)
  (labels ((do-last (d n) (mapcar (λ (d) (funcall rec conf (pre/or-all d))) (last d n))))
    `(∈ (:par ,(gk conf :par t) :cnt ,(gk conf :cnt t)
         :itr ,(gk conf :itr t) :key ,(gk conf :itr t))
       ,(case (length d) ((0 (error "xpr: missing args.")))
          (1 (compile/?xpr/bool rec conf (pre/** d)))
          (2 `(if ,(compile/?xpr/bool rec conf (pre/** (butlast d 1))) ,@(do-last d 1)))
          (otherwise `(if ,(compile/?xpr/bool rec conf
                             (pre/** (butlast d 2))) ,@(do-last d 2)))))))

(defun compile/?txpr (rec conf d) (funcall rec conf `(?mxpr ,d)))
(defun compile/?mxpr (rec conf d)
  (awg (f dat)
    `(let ((,dat ,(gk conf :dat)))
       (m/replfx (,dat ,f)
        ,@(loop with conf* = `((:dat . ,f) (:itr . ,dat) (:par . ,dat) ,@conf)
            for d* in d nconc `(,(funcall rec conf* `(?xpr ,@(butlast d*) t nil))
                                ,(funcall rec conf* (pre/or-all (car (last d*))))))))))

(defun compile/?srch (rec conf d)
  (unless d (error "?srch: missing args."))
  (awg (res) `(let ((,res (mav)))
                ,(if (> (length d) 1) (funcall rec conf
                                        `(?txpr ,@(butlast d) (vex ,res ,(first (last d)))))
                                      (funcall rec conf `(?txpr ,@d (vex ,res _))))
                ,res)))
(defun compile/?rec/vars (rec conf d)
   (labels ((rec (x) (funcall rec conf x)))
     (loop for o in d nconc
       (case (length o)
         (1 `(with ,(car o)))
         (2 `(for ,(car o) = ,(rec (second o)) then ,(rec (second o))))
         (3 `(for ,(car o) = ,(rec (second o)) then ,(rec (third o))))
         (otherwise (error "?rec: var init, wanted 1-3 args, got: ~a." o))))))
(defun compile/?rec (rec conf d) ; (?rec (< (inum) 10) (+ _ 1))
  (unless (< 1 (length d) 4) (error "?rec: expected 2-3 arguments. got: ~a." d))
  (awg (i ∇-)
    (let ((d (lpad-lst 3 d)))
      `(let ((,∇- ,(gk conf :dat)) (,i 0))
         (∈ (:par ,(gk conf :dat) :cnt ,i :key ,i)
            (loop ,@(compile/?rec/vars rec conf (car d))
                  while ,(funcall rec (dat/new conf ∇-) (second d))
                  do (setf ,∇- ,(funcall rec (dat/new conf ∇-)
                                         (third d)) ,i (+ ,i 1))))
         (values ,∇- ,i)))))


; TODO: operate on hts too?
; TODO: smarter selectors? key, index as grpfx; aggfx
(defun compile/?grp (rec conf d)
  (unless (< 0 (length d) 3) (error "?grp: expected 1 or 2 args. got: ~a." d))
  (awg (i kvres key itr par dat acc)
    `(loop with ,kvres of-type hash-table = (make$)
           with ,par of-type vector = (vec! ,(gk conf :dat))
           for ,itr across ,par for ,i from 0
           for ,key = ,(funcall rec (dat/new conf itr) (first d))
           for ,acc = (gethash ,key ,kvres (new*))
           do (∈ (:par ,par :cnt ,i :itr ,itr :key ,key)
                 (let ((,dat ,(case (length d) (1 itr)
                                (2 (funcall rec (dat/new conf itr) (second d))))))
                  (setf (gethash ,key ,kvres) (psh* ,acc ,dat))))
           finally (return ,kvres))))

(defun proc-qry (q &optional conf*) "compile lqn query"
  (awg (dat fn fi)
  (labels
    ((rec (conf d* &aux (d (pre/scan-clause d* nil)))
       (cond
         ((dat? d) (gk conf :dat))
         ((stringp d) d) ; remember that this order is important
         ((vectorp d) (rec conf `(?map ,@(coerce d 'list))))
         ((atom d) d)
         ((qop? :||    d) (compile/||    #'rec conf (pre/|| (cdr d))))
         ((qop? :**    d) (compile/**    #'rec conf (pre/** (cdr d))))
         ((qop? :$*    d) (compile/$*    #'rec conf (pre/$$ (cdr d))))
         ((qop? :*$    d) (compile/*$    #'rec conf (pre/$$ (cdr d))))
         ((qop? :$$    d) (compile/$$    #'rec conf (pre/$$ (cdr d))))
         ((qop? :?map  d) (compile/?map  #'rec conf (pre/?map (cdr d))))
         ((qop? :?xpr  d) (compile/?xpr  #'rec conf (cdr d)))
         ((qop? :@     d) (compile/@     #'rec conf (cdr d)))
         ((qop? :?fld  d) (compile/?fld  #'rec conf (cdr d)))
         ((qop? :?mxpr d) (compile/?mxpr #'rec conf (cdr d)))
         ((qop? :?txpr d) (compile/?txpr #'rec conf (cdr d)))
         ((qop? :?srch d) (compile/?srch #'rec conf (cdr d)))
         ((qop? :?rec  d) (compile/?rec  #'rec conf (cdr d)))
         ((qop? :?grp  d) (compile/?grp  #'rec conf (cdr d)))
         ((car- lqnfx? d) `(,(psymb 'lqn (car d)) ,@(rec conf (cdr d))))
         ((consp d) (cons (rec conf (pre/scan-clause (car d))) (rec conf (cdr d))))
         (t (error "lqn: unexpected clause: ~a~%in: ~a." d q)))))
      `(λ (,dat ,fn ,fi) (q∈ (,dat ,fn ,fi)
                             ,(rec `((:dat . ,dat) ,@conf*) q))))))

(defun qry/show (q cq)
  (format t "
██ COMPILED ██████████████████████████
██ q:   ~s
██ ---------~%   ~s
██ END      ██████████████████████████~%" q cq))

(defmacro qryd (dat q &key db) "run lqn query on dat"
  (let ((cq (proc-qry q)))
    (when db (qry/show q cq))
    `(funcall ,cq ,dat ":internal:" 0)))
(defmacro qry (dat &rest rest) "query data. rest is wrapped in the pipe operator."
  `(qryd ,dat (|| ,@rest)))
(abbrev @q qry)
(defmacro qrydb (dat &rest rest) "query data. rest is wrapped in the pipe operator."
  `(qryd ,dat (|| ,@rest) :db t))
(defun qryl (dat q &key db) "compile lqn query and run on dat"
  (eval `(qryd ,dat ,q :db ,db)))
(defmacro jsnqryf (fn q &key db) "run lqn query on json file, fn"
  `(qryd (jsnloadf ,fn) ,q :db ,db))

