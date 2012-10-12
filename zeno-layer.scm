;;; 图层脚本 for GIMP 2.8
;; Copyright (C) 2012 Zeno Zeng <zenoes@qq.com>

;; Author: Zeno Zeng
;; Keywords: photo,color,yellow
;; Created: 2012-08-08
;; Time-stamp: <2012-08-12 13:51:34>
;; Version: 0.1
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;;; CODE

(define (script-fu-delete-other-layers img drawable)
  (gimp-image-undo-group-start img)

  ;; 置顶当前层
  (gimp-image-raise-item-to-top img drawable)

  (let ((layer (car (gimp-image-get-layers img)))
	(layers (cadr (gimp-image-get-layers img))))
    (while (> layer 1)
	   (set! layer (- layer 1))
	   (gimp-image-remove-layer img (aref layers layer))))

  ;; 更新显示
  (gimp-displays-flush)
  
  (gimp-image-undo-group-end img))

(script-fu-register "script-fu-delete-other-layers"
		    "<Image>/Layer/删除其他图层"
		    "仅仅保留当前图层"
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE	"Image"			0
		    SF-DRAWABLE "drawable"              0) 
