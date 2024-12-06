(in-package :lqn)

(defvar *qmodes* '(:+ :? :- :%))
(defvar *operators* '(:|| :?pipe :?select :@ :?map :?filter :*$ :$*
                      :?xpr :?txpr :?mxpr
                      :?fld :?srch :?grp :?rec))
(defvar *opt* '(optimize (speed 3) (safety 1)))
(defvar *fxns* '(:err :wrn :nope :noop :lit :qt :hld :ghv :pnum :inum :cnt :λ
                 :fmt :out :jsnstr
                 :fn :fi :ctx  :par :itr :key :val :compct :?? :@get :@*
                 :read? :some? :all? :none? :smth? :size?
                 :new* :new$ :cat* :cat$
                 :ind* :sel :seq :apply* :grp :uniq
                 :flatn* :flatall* :flatn$
                 :range :linspace :pop* :psh* :head :tail
                 :pref? :suf? :sub? :subx? :ipref? :isuf? :isub? :isubx?
                 :lpad :rpad :nstr :sup :sdwn :mkstr :repl :strcat :splt :join
                 :msym? :is? :kv? kw? :sym? :ssym? :sym! :trim
                 :num!? :num? :flt! :flt!? :flt? :int! :int!? :int?
                 :lst? :lst! :lst!? :seq? :seq!? :str! :str? :str!? :kw! :vec! :vec? :vec!?
                 :path? :subdir :subfiles :ls :dir? :file? :cwd :now :cmd :cd))
(defun cmd-args ()
  (or #+SBCL sb-ext:*posix-argv* #+LISPWORKS system:*line-arguments-list*
      #+CMU extensions:*command-line-words* nil))

(defun terminate (status &optional (silent t)) ;https://www.rosettacode.org/wiki/Program_termination#Common_Lisp
  (unless silent (format t "~%terminated with status: ~a~%" status))
  #+sbcl (sb-ext:quit :unix-status status) #+ccl (ccl:quit status)
  #+clisp (ext:quit status) #+cmu (unix:unix-exit status)
  #+abcl (ext:quit:status status) #+allegro (excl:exit status :quiet t)
  #+gcl (common-lisp-user::bye status) #+ecl (ext:quit status))

(defmacro prtcomp (&rest o) ; (*print-readably* t) (*print-escape* t)
  `(let ((*print-case* :downcase) (*print-gensym* nil)) (progn ,@o)))
(defmacro with-struct ((name . fields) struct &body body)
  (let ((gs (gensym)))
    `(let ((,gs ,struct))
       (let ,(mapcar #'(lambda (f)
                         `(,f (,(psymb (symbol-package name) name f) ,gs)))
                     fields)
         ,@body))))
(defmacro with-gensyms (syms &body body)
  `(let ,(mapcar #'(lambda (s) `(,s (gensym ,(symbol-name s)))) syms) ,@body))

(defmacro abbrev (short long)
  `(defmacro ,short (&rest args) ,(format nil "alias: ~s~&" long) `(,',long ,@args)))
(abbrev awg with-gensyms)        (abbrev mav make-adjustable-vector)
(abbrev dsb destructuring-bind)  (abbrev mvb multiple-value-bind)
(abbrev mvc multiple-value-call) (abbrev mvl multiple-value-list)
(abbrev vpe vector-push-extend)  (defmacro vex (v o) `(vpe ,o ,v))

(defun extsym? (&optional (pkg "LQN") default &aux (pkg (find-package pkg)))
  "list external symbols of package"
  (if pkg (loop for s being the external-symbols of pkg collect s) default))

(defmacro λ (&rest rest) `(lambda ,@rest))
(defun internal-path-string (&optional (path "") (pkg :lqn)) (declare (string path))
  (namestring (asdf:system-relative-pathname pkg path)))

(defun d? (s) "describe symbol." (describe s)) (defun i? (s) "inspect s" (inspect s))
(defun v? (&optional (silent t)
           &aux (v (slot-value (asdf:find-system 'lqn) 'asdf:version)))
  "return/print lqn version." (unless silent (format t "~&LQN version: ~a~%." v)) v)

(defun make-adjustable-vector (&key init (type t) (size 128))
  (if init (make-array (length init) :fill-pointer t :initial-contents init
                                     :element-type type :adjustable t)
           (make-array size :fill-pointer 0 :element-type type :adjustable t)))

