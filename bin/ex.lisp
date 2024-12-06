
(load "~/quicklisp/setup.lisp")

(ql:quickload :lqn :silent t)
(in-package :lqn)

(print (qry "1 x 1 x 7 x 100" (splt _ :x) int!? (?fld 0 (+ _))))         ;; 109
(print (qry "1 x 1 x 7 x 100" (splt _ :x) int!? (?fld 0 +)))             ;; 109
(print (qry "1 x 1 x 7 x 100" (splt _ :x) int!? (?fld 0 acc (- _ acc)))) ;; 93

(pretty-json
  (qry "abc x def x gehiil x iiii"
       (splt _ :x) str!? trim                     ; split and trim
       (new$ :in (par)                            ; new kv with input
             :len (pnum)                          ; input length
             :items #((new$ :s _ :len (inum)))))) ; and substr lengths
; { "in": "abc x def x gehiil x iiii",
;   "len": 25,
;   "items": [ { "s": "abc", "len": 3 },    { "s": "def", "len": 3 },
;              { "s": "gehiil", "len": 6 }, { "s": "iiii", "len": 4 } ] }

(print (ldnout (qry #("1 x 1 x 7 x 100" "3 x 8 x 30")
                    #((splt _ :x) #(int!?) ; for each row, split and parse as int
                      (?fld 0 +)))))    ; sum each row
;; #(109 41)

(print (qry "aaayyy x abc x def x auiuu x aaaaa"
            (splt _ :x) trim                       ; split
           #((?xpr :a :-@b sup (str! _ :-miss))))) ; search & replace
;; #("AAAYYY" "abc-miss" "def-miss" "AUIUU" "AAAAA")

(print (qry #((a b xxx) (a b c) (a b (c xxx)))
            #((?txpr (msym? _ xxx)         ; recursive search & replace
                     (symb _ :-HIT---))))) ; with new symbol
;; #((A B XXX-HIT---) (A B C) (A B (C XXX-HIT---)))

(print (qry #((a bbbxxx xxx) (a b c) (a b (c xxx)))
             ; symbols with "xxx", but not "bbb"
             (?txpr (-@msym? _ "bbb") (+@msym? _ "xxx")
                    (sym! _ :-HIT---))))
;; #((A BBBXXX XXX-HIT---) (A B C) (A B (C XXX-HIT---)))

(pretty-json (jsnqryf (internal-path-string "data/sample.json")
                      (|| #{:_id (:things #[:name])})))
;;  [ { "_id": "65679d23d38d711eaf999e89",
;;      "things": [ "Chris" ] },
;;    { "_id": "65679d23fe33bc4c240675c0",
;;      "things": [ "Winters", "Haii", "Klein" ] },
;;    { "_id": "65679d235b4143d2932ea17a",
;;      "things": [ "Star", "Ball" ] } ]

(print (lqn:qry #(0 1) (?rec (< (@ -1) 10000)
                              (cat* _ (apply* + (tail _ 2))))
                       #((str! "- " (cnt) ": " _))
                        (join _ #\Newline)))
;; - 0: 0
;; - 1: 1
;; - 2: 1
;; - 3: 2
;; - 4: 3
;; - 5: 5
;; ...

(print (lqn:ldnout (lqn:qry (lqn:jsnloads "[{\"a\": 1, \"b\": 23},
                                            {\"a\": 11, \"b\": 123},
                                            {\"a\": 11, \"b\": 123} ]")
                            (?grp :a (str! (key) "-" (@ :b))))))
;; ((1  . #("1-23"))
;;  (11 . #("11-123" "11-123")))

