(in-package :jqn)

(defun jqn/show (q compiled)
 (format t "
██ COMPILED ██████████████████████████
██ q:   ~s
██ ---
   ~s
██ ██████████████████████████~%" q compiled))

(defun ensure-vector (v)
  (declare (sequence v))
  (etypecase v (vector v) (list (coerce v 'vector))))

(defmacro push? (lst k v)
  (declare (symbol lst)) "push (k . v) to lst if v"
  (awg (v*) `(let ((,v* ,v)) (when ,v* (push `(,',(kv k) . ,,v*) ,lst)))))

(defmacro push! (lst k v &optional default)
  (declare (symbol lst)) "push (k . v) to lst if v; otherwise push (k . default)"
  (awg (v*) `(let ((,v* ,v))
               (if ,v* (push `(,,(kv k) . ,,v*) ,lst)
                       (push `(,,k . ,,default) ,lst)))))

(defun loadf (fn)
  (declare (string fn)) "load json from file fn"
  (with-open-file (f fn :direction :input)
    (let ((yason:*parse-json-arrays-as-vectors* t))
      (yason:parse f))))

(defun dumps (o &key (s *standard-output*) indent)
  (declare (stream s) (boolean indent)) "encode o as json to stream, s"
  (let ((yason:*list-encoder* 'yason:encode-alist))
    (yason:encode o (yason:make-json-output-stream s :indent indent))))

(defun car-kv? (d) (and (listp d) (keywordp (car d))))
(defun car-itr? (d) (and (listp d) (eq '* (car d))))
(defun all? (d) (eq d '_))

(defun compile/itr/preproc (q)
  (loop for k in q
        collect (etypecase k
                  (keyword `(,@(unpack-selectors k) _))
                  (cons `(,@(unpack-selectors (car k)) ,@(cdr k)))
                  (string `(,(unpac-selectors k) _)))))

(defun jqn (src q)
  "compile jqn query"
  (labels
    ((compile/itr (src d)
       (awg (res lst o)
         (let ((loop-body
                 ; TODO: MODE HERE
                 (loop for (mode kk vv) in (reverse d)
                       ; do (print mode)
                       collect `(,(ecase mode (:_ 'push?) (+@ 'push!))
                                 ,res ,kk
                                 ,(rec `(gethash ,kk ,o) vv)))))
           `(loop with ,lst = (make-adjustable-vector)
                  for ,o across (ensure-vector ,src)
                  for ,res = (list)
                  do (progn ,@loop-body
                            (vextend ,res ,lst))
                  finally (return ,lst)))))
     (rec (src d) (cond ((all? d) src) ((atom d) d)
                        ((car-itr? d) (compile/itr src
                                        (compile/itr/preproc (cdr d))))
                        ((car-kv? d) d)
                        (t (error "not implemented: ~a" d)))))
    (rec src q)))

(defmacro jqnd (dat &key q db)
  (declare (boolean db) (cons q)) "query dat"
  (awg (dat*) (let ((compiled (jqn dat* q)))
                (when db (jqn/show q compiled))
                `(let ((,dat* ,dat)) ,compiled))))
(defmacro jqnf (fn &key q db)
  (declare (boolean db) (cons q)) "query file fn"
  `(jqnd (loadf ,fn) :q ,q :db ,db))

(defun jqnfl (dat &key q)
  (declare (string dat)) "compile query and run it on dat"
  (awg (dat*) (eval `(let ((,dat* ,dat))
                       (jqnf ,dat* :q ,q)))))

