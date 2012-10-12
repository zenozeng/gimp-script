;; 导出目录内所有xcf文件到子文件夹output，并resize到640*480
;; gimp -i -b '(batch-publish "*.xcf")' -b '(gimp-quit 0)'
;; .bashrc
;; alias xcfpublish="gimp -i -b '(batch-publish \"*.xcf\")' -b '(gimp-quit 0)'"

(define (batch-publish pattern )
  (let* ((filelist (cadr (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
		  (output (string-append (string-append "output/" filename) ".jpg"))
                  (image (car (gimp-file-load RUN-NONINTERACTIVE
                                              filename filename)))
                  (drawable (car (gimp-image-flatten image))))

	     (gimp-image-scale image 640 480)

	     (file-jpeg-save RUN-NONINTERACTIVE
			     image drawable output output 1 0 1 0 "Created with Gimp" 0 1 0 0)
             (gimp-image-delete image))
           (set! filelist (cdr filelist)))))

;; 导出目录内所有xcf文件到子文件夹output
;; gimp -i -b '(batch-publish-ori "*.xcf")' -b '(gimp-quit 0)'

(define (batch-publish-ori pattern )
  (let* ((filelist (cadr (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
		  (output (string-append (string-append "output/" filename) ".jpg"))
                  (image (car (gimp-file-load RUN-NONINTERACTIVE
                                              filename filename)))
                  (drawable (car (gimp-image-flatten image))))

	     (file-jpeg-save RUN-NONINTERACTIVE
			     image drawable output output 1 0 1 0 "Created with Gimp" 0 1 0 0)
             (gimp-image-delete image))
           (set! filelist (cdr filelist)))))


;; 导出目录内所有xcf文件的最低图层到子文件夹ori
;; gimp -i -b '(batch-publish-lowest-layer "*.xcf")' -b '(gimp-quit 0)'
;; .bashrc
;; alias xcfpublishl="gimp -i -b '(batch-publish-lowest-layer \"*.xcf\")' -b '(gimp-quit 0)'"

(define (batch-publish-lowest-layer pattern )
  (let* ((filelist (cadr (file-glob pattern 1))))
    (while (not (null? filelist))
           (let* ((filename (car filelist))
		  (output (string-append (string-append "ori/" filename) ".jpg"))
                  (image (car (gimp-file-load RUN-NONINTERACTIVE
                                              filename filename)))
		  ;; get layers返回两个参数，前者是计数，后者是图层array
                  (drawable (aref (cadr (gimp-image-get-layers image)) (- (car (gimp-image-get-layers image)) 1))))

	     (file-jpeg-save RUN-NONINTERACTIVE
			     image drawable output output 1 0 1 0 "Created with Gimp" 0 1 0 0)
             (gimp-image-delete image))
           (set! filelist (cdr filelist)))))
