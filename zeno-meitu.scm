;;; 美图滤镜 for GIMP 2.8
;; Copyright (C) 2012 Zeno Zeng <zenoes@qq.com>

;; Author: Zeno Zeng
;; Keywords: photo,color,yellow
;; Created: 2012-08-08
;; Time-stamp: <2012-08-12 13:51:03>
;; Version: 0.1
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; 简单介绍：
;; 注意：这两支滤镜都需要脸部较亮才能正常使用。适用性很差。
;; - 磨皮：
;;   这支滤镜是自动磨皮，效果一般，原理是高斯模糊加上蒙版，对黑色头发控制较好。
;; - 加亮：
;;   利用柔光滤镜加上蒙版的效果。

;;; CODE

(define (script-fu-meitu-mopi img value)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 设定
  (let ((Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(ori nil)
	(mask nil)
	(newmask nil)
	(merged nil))

    ;; 磨皮开始

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "磨皮")))
    (set! ori (car (gimp-layer-new-from-visible img img "磨皮")))
    (gimp-image-insert-layer img new 0 0)
    (gimp-image-insert-layer img ori 0 0)

    ;; 添加蒙版
    (set! mask (car (gimp-layer-create-mask ori 5)))
    (gimp-layer-add-mask ori mask)
    (gimp-invert mask)

    (set! newmask (car (gimp-layer-create-mask new 5)))
    (gimp-layer-add-mask new newmask)

    ;; 高斯模糊
    (plug-in-gauss 1 img new value value 0)

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "磨皮")))
    (gimp-image-insert-layer img new 0 0)
    
    ;; 合并图层
    (set! merged (car (gimp-image-merge-down img new 0)))
    (set! merged (car (gimp-image-merge-down img merged 0)))

    (gimp-image-undo-group-end img)

    ;; 刷新显示
    (gimp-displays-flush)))

(define (script-fu-meitu-liangyan img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 设定
  (let ((Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(ori nil)
	(mask nil)
	(newmask nil)
	(merged nil))

    ;; 磨皮开始

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "亮颜")))
    (set! ori (car (gimp-layer-new-from-visible img img "亮颜")))
    (gimp-image-insert-layer img new 0 0)
    (gimp-image-insert-layer img ori 0 0)

    ;; 添加蒙版
    (set! mask (car (gimp-layer-create-mask ori 5)))
    (gimp-layer-add-mask ori mask)
    (gimp-invert mask)

    (set! newmask (car (gimp-layer-create-mask new 5)))
    (gimp-layer-add-mask new newmask)

    ;; 高斯模糊
    (plug-in-softglow 1 img new 10 0.75 0.85)

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "亮颜")))
    (gimp-image-insert-layer img new 0 0)
    
    ;; 合并图层
    (set! merged (car (gimp-image-merge-down img new 0)))
    (set! merged (car (gimp-image-merge-down img merged 0)))

    (gimp-image-undo-group-end img)

    ;; 刷新显示
    (gimp-displays-flush)))


(script-fu-register "script-fu-meitu-mopi"
		    _"<Image>/美图/磨皮"
		    _"利用模糊来磨皮"
		    "Zeno Zeng"
		    "Zeno Zeng"
		    "2012"
		    "*"
		    SF-IMAGE        "Image"     0
		    SF-ADJUSTMENT	"高斯模糊半径" '(25 0 999 1 10 1 1))


(script-fu-register "script-fu-meitu-liangyan"
		    _"<Image>/美图/亮颜"
		    _"利用模糊来磨皮"
		    "Zeno Zeng"
		    "Zeno Zeng"
		    "2012"
		    "*"
		    SF-IMAGE        "Image"     0)
