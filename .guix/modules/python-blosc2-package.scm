;;; This file follows the suggestions in the article "From development
;;; environments to continuous integration—the ultimate guide to software
;;; development with Guix" by Ludovic Courtès at the Guix blog:
;;; <https://guix.gnu.org/es/blog/2023/from-development-environments-to-continuous-integrationthe-ultimate-guide-to-software-development-with-guix/>.
;;;
;;; Use "guix shell -CP -L /path/to/c-blosc2/.guix/modules -D -f guix.scm" to
;;; get a container shell with build dependencies.
;;;
;;; Use "guix build -L $PWD/.guix/modules -L /path/to/c-blosc2/.guix/modules
;;; python-blosc2" to build.

(define-module (python-blosc2-package)
  #:use-module (guix)
  #:use-module (guix build-system pyproject) ;for python-ndindex
  #:use-module (guix build-system python)
  #:use-module (guix git-download)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 textual-ports)
  #:use-module (gnu packages check)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages version-control)
  #:use-module (c-blosc2-package)
)

;; Generated by "guix import pypi ndindex"
;; (except for build arguments and native inputs).
(define-public python-ndindex
  (package
    (name "python-ndindex")
    (version "1.7")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "ndindex" version))
              (sha256
               (base32
                "1lpgsagmgxzsas7g8yiv6wmyss8q57w92h70fn11rnpadsvx16xz"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f))
    (native-inputs (list python-numpy))
    (home-page "https://quansight-labs.github.io/ndindex/")
    (synopsis "A Python library for manipulating indices of ndarrays.")
    (description
     "This package provides a Python library for manipulating indices of ndarrays.")
    (license license:expat)))

(define (current-source-root)
  (dirname (dirname (current-source-directory))))

(define (get-python-blosc2-version)
  (let ((version-path (string-append (current-source-root) "/blosc2/version.py"))
        (version-rx (make-regexp
                     "^__version__\\s*=\\s*\"([^\"]*)\".*"
                     regexp/newline)))
    (call-with-input-file version-path
      (lambda (port)
        (let* ((version-body (get-string-all port))
               (version-match (regexp-exec version-rx version-body)))
          (and version-match
               (match:substring version-match 1)))))))

(define vcs-file?
  ;; Return true if the given file is under version control.
  (or (git-predicate (current-source-root))
      (const #t)))

(define-public python-blosc2
  (package
    (name "python-blosc2")
    (version (get-python-blosc2-version))
    (source (local-file "../.."
                        "pyblosc2-checkout"
                        #:recursive? #t
                        #:select? (lambda (path stat)
                                    (and (vcs-file? path stat)
                                         (not (string-contains path
                                               "/blosc2/c-blosc2"))))))
    (build-system python-build-system)
    (arguments
     (list #:phases #~(modify-phases %standard-phases
                        (replace 'build
                          (lambda* (#:key inputs #:allow-other-keys)
                            (invoke "python" "setup.py" "build"
                                    "-DUSE_SYSTEM_BLOSC2:BOOL=YES")))
                        (replace 'check
                          (lambda* (#:key tests? #:allow-other-keys)
                            (when tests?
                              (invoke "env" "PYTHONPATH=." "pytest")))))))
    (inputs (list c-blosc2))
    (propagated-inputs (list python-msgpack python-ndindex python-numpy
                             python-py-cpuinfo))
    (native-inputs (list cmake-minimal pkg-config python-cython python-pytest
                         python-scikit-build))
    (home-page "https://github.com/blosc/python-blosc2")
    (synopsis "Python wrapper for the Blosc2 data compressor library")
    (description
     "Blosc2 is a high performance compressor optimized for binary
data.  It has been designed to transmit data to the processor cache faster
than the traditional, non-compressed, direct memory fetch approach via a
@code{memcpy()} system call.

Python-Blosc2 wraps the C-Blosc2 library, and it aims to leverage its new API
so as to support super-chunks, multi-dimensional arrays, serialization and
other features introduced in C-Blosc2.

Python-Blosc2 also reproduces the API of Python-Blosc and is meant to be able
to access its data, so it can be used as a drop-in replacement.")
    (license license:bsd-3)))

python-blosc2
