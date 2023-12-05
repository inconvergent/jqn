#!/usr/local/bin/sbcl --script

(load "~/quicklisp/setup.lisp")

(ql:quickload :auxin :silent t)
(ql:quickload :jqn :silent t)

(in-package :jqn)


(defun main (args)
  ; (loop for i from 0
  ;       for x across
  ;         (qryf "./sample.json" :db t
  ;               :q (*  _id
  ;                     (+@things (* name id))
  ;                     (+@force 333)))
  ;       do (print i) (print x))

  (loop for i from 0
        for x across
          (qryf "./sample.json" :db t
                :q (*  _id
                      (+@things (* name id))
                      ; (+@force (@ :msg))
                      ))
        do (print i) (print x))


  )

(main (auxin:cmd-args))
