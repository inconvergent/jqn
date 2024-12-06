(in-package :lqn)

(defvar *docstring-map* nil)

(defun -strsrt (l) (sort l #'string-lessp :key #'car))
(defun desc (sym) (declare (symbol sym))
  (let ((d (with-output-to-string (*standard-output*)
             (describe sym))))
    (strcat (mapcar (lambda (s) (mkstr " ; " s #\Newline))
                    (butlast (str-split d (mkstr #\Newline)))))))

(defun docstrings (sym)
  (strcat (mapcar (lambda (o) (mkstr o #\Newline))
                  (remove-if-not #'identity (list (documentation sym 'variable)
                                                  (documentation sym 'function)
                                                  (documentation sym 'setf))))))
(defun select-docs (sym) (declare (symbol sym))
  (let* ((docs (find-if (lambda (c) (eq sym c)) *docstring-map* :key #'car))
         (idocs (docstrings sym))
         (skip (find :skip docs))
         (desc (unless (find :nodesc docs) (desc sym))))
    (declare (list docs))
    (values
      (cond (docs (format nil "~&~a~@[~&~%~a~&~]~&" (cadr docs) desc))
            ((and idocs (> (length idocs) 0))
               (format nil "~&~a~@[~&~%~a~&~]~&" desc nil))
            (t (format nil "~&:missing:~%~@[~&~%~a~&~]~&" desc)))
      skip)))

(defmacro pckgs (pkg)
  (awg (sym) `(-strsrt (loop for ,sym being the external-symbols of (find-package ,pkg)
                             collect (list (mkstr ,sym) ,sym)))))

(defmacro ext-symbols? (pkg &optional mode)
  "list all external symbols in pkg. use :verbose to inlcude docstring.
use :pretty to print verbose output to stdout in a readable form."
  (awg (str sym doc skip)
    (case mode
      (:pretty
        `(loop for (,str ,sym) in (pckgs ,pkg)
               do (mvb (,doc ,skip) (select-docs ,sym)
                       (unless ,skip (format t "~&```~&~a~&```~%" ,doc)))))
      (:pairs `(loop for (,str ,sym) in (pckgs ,pkg)
                     collect (list ,str (select-docs ,sym))))
      (otherwise `(loop for (,str ,sym) in (pckgs ,pkg) collect ,str)))))

(defun map-docstring (&rest rest)
  (declare (list rest)) "register docs info associated with symbol (car rest)."
  (setf *docstring-map* (remove-if (lambda (cand) (eq (car cand) (car rest))) *docstring-map*))
  (push rest *docstring-map*))

