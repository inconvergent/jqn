(asdf:defsystem #:lqn
  :description "Lisp Query Notation"
  :version "2.1.2"
  :author "anders hoff / @inconvergent / inconvergent@gmail.com"
  :in-order-to ((asdf:test-op (asdf:test-op #:lqn/tests)))
  :licence "MIT" :pathname "src/" :serial nil
  :depends-on (#:yason #:uiop)
  :components ((:file "packages")
               (:file "init" :depends-on ("packages"))
               (:file "basic-utils" :depends-on ("init"))
               (:file "reader-macros" :depends-on ("basic-utils"))
               (:file "qry-utils" :depends-on ("reader-macros" "basic-utils"))
               (:file "docs" :depends-on ("qry-utils"))
               (:file "io" :depends-on ("docs"))
               (:file "pre-qry" :depends-on ("io" "qry-utils" "docs"))
               (:file "qry-operators" :depends-on ("pre-qry"))
               (:file "sh" :depends-on ("qry-operators"))
               (:file "qry-extra" :depends-on ("qry-operators"))))

(asdf:defsystem #:lqn/tests
  :depends-on (#:lqn #:prove #:uiop #:asdf)
  :version "2.1.2"
  :perform (asdf:test-op (o s) (uiop:symbol-call ':lqn-tests '#:run-tests))
  :pathname "test/" :serial t
  :components ((:file "run")))
