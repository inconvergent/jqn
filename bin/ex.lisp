#!/usr/local/bin/sbcl --script

(load "~/quicklisp/setup.lisp")

(ql:quickload :auxin :silent t)
(ql:quickload :jqn :silent t)
; (in-package :jqn)

   ; (jqn:jsnout (jqn:jsnqryf "./sample.json" :db t (|| #{_ _id}) :db t) :indent t)

(defun main ()
  (print
    ; (jqn::preproc/$$itr
    ;     '(ccc :ddd "IIUJ" "%@UU" ?@aa ?@bb ("cc" (progn _))
    ;       (:% "xBC" (print _)) (:% "ABC" _)))
    (mapcar #'print
     (jqn::preproc/**filter
        '(ccc :ddd "IIUJ" "%@UU" ?@aa ?@bb ("cc" (progn _))
          (% "ABC" (print _)) (:% "ABC" _))))

   ; (jqn:jsnout (jqn:jsnqryf "./sample.json" (||

   ;                                            #{(:?@_id (print _))}
   ;                                            ; #{(:? _id (print _))}
   ;                                            ; #{(?@_id print _)}
   ;                                            )
   ;                          :db t
   ;                          ) :indent t)

   )
  )

(main)


; ██ COMPILED ██████████████████████████
; ██ q:   (*$ THINGS (+@THINGS (*$ ?@ID)))
; ██ ---
;    (LABELS ((JQN::FN ()
;               NIL)
;             (JQN::CTX ()
;               NIL))
;      (LOOP JQN::WITH #:IRES1 = (JQN::MAV)
;            JQN::FOR #:DAT3 JQN::ACROSS (JQN::ENSURE-VECTOR #:DAT*0)
;            JQN::FOR #:KRES2 = (JQN::NEW-HT)
;            DO (PROGN
;                (SETF (GETHASH "things" #:KRES2) (JQN:@ #:DAT3 "things"))
;                (SETF (GETHASH "things" #:KRES2)
;                        (LOOP JQN::WITH #:IRES4 = (JQN::MAV)
;                              JQN::FOR #:DAT6 JQN::ACROSS (JQN::ENSURE-VECTOR
;                                                           (JQN:@ #:DAT3
;                                                                  "things"))
;                              JQN::FOR #:KRES5 = (JQN::NEW-HT)
;                              DO (PROGN
;                                  (SETF (GETHASH "id" #:KRES5)
;                                          (JQN:@ #:DAT6 "id"))
;                                  (JQN::VEXTEND #:KRES5 #:IRES4))
;                              JQN::FINALLY (RETURN #:IRES4)))
;                (JQN::VEXTEND #:KRES2 #:IRES1))
;            JQN::FINALLY (RETURN #:IRES1)))


  ; jqn -v '#{ (things
  ;              #{(%@extra (maybe string-upcase _))})}' bin/sample.json

  ; {
  ;   "things": [
  ;     {
  ;       "extra": "EXTRA99"
  ;     }
  ;   ]
  ; },
  ; {
  ;   "things": [
  ;     {
  ;       "extra": "EXTRA1"
  ;     },
  ;     {
  ;       "extra": "EXTRA2"
  ;     },
  ;     null
  ;   ]
  ; },
  ; {
  ;   "things": [
  ;     null,
  ;     null
  ;   ]
  ; }
