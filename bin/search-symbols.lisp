(in-package :lqn)

(block main
(let ((q (second (cmd-args)))
      (pkg (third (cmd-args)))
      (veq-symbs (vec! veq::*docstring-map*)))
 (labels ((veq-special (s &aux (res (and (equal "VEQ" (package-name (symbol-package s)))
                                         (second (find s veq-symbs :key #'car)))))
             (when res (str! "veq:" s " (vprogn)" #\Newline  res))))
  (unless q (return-from main))
  (qry (ls "~/common-lisp/*/src/packages.lisp")
      dat-read-file _@flatn* second                     ; package names
      [(or (not pkg) (isub? s@_ pkg))] extsym? _@flatn* ; filter packages
      [(or (string= s@q "_") (isub? s@_ q))]            ; filter symbol ; _ matches all
      #((join (head (splt (or (veq-special _)
                              (stdstr _@describe))
                          #.(str! #\Newline) nil) -1)   ; some formatting
               #\Newline ";; ")
        (out "~&~&██ ~a~&~%" _))))))

