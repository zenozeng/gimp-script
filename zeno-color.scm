;;; 调色滤镜 for GIMP 2.8
;; Copyright (C) 2012 Zeno Zeng <zenoes@qq.com>

;; Author: Zeno Zeng
;; Keywords: photo,color
;; Created: 2012-08-08
;; Time-stamp: <2012-09-16 16:40:48>
;; Version: 0.7
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; Changelog:
;;  Version 0.7 (2012-09-16)
;;    - 删除lomo
;;  Version 0.6 (2012-08-22)
;;    - 添加靓蓝
;;  Version 0.5 (2012-08-11)
;;    - 添加光效
;;    - 去彩更名为降彩
;;  Version 0.4 (2012-08-10)
;;    - 修改Lomo，取消高斯模糊
;;    - 添加色温（升温、降温）
;;  Version 0.3 (2012-08-09)
;;    - 添加LOMO
;;    - 改进语句
;;    - 修复咖啡在撤销上的bug
;;  Version 0.2 (2012-08-08)
;;    - 添加咖啡、去彩
;;    - 修复前景色设定后不恢复的bug

;;; CODE

(define (script-fu-tiaose-jiangcai img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 盖印图层
  (gimp-image-insert-layer img (car (gimp-layer-new-from-visible img img "降彩")) 0 0)

  ;; 设定drawable，前景，背景
  (let ((drawable (car (gimp-image-get-active-drawable img)))
	(Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(merged nil))

    ;; 降低饱和度
    (gimp-desaturate drawable)

    ;; 添加蒙版
    (gimp-layer-add-mask
     drawable
     (car (gimp-layer-create-mask drawable 5)))

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "柔光")))
    (gimp-image-insert-layer img new 0 0)

    ;; 合并图层
    (set! merged (car (gimp-image-merge-down img new 0)))

    (gimp-image-undo-group-end img))

  ;; 刷新显示
  (gimp-displays-flush))
(script-fu-register "script-fu-tiaose-jiangcai"
		    "<Image>/调色/降彩"
		    "降低图像的色彩."
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)

(define (script-fu-tiaose-lianglan img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 盖印图层
  (gimp-image-insert-layer img (car (gimp-layer-new-from-visible img img "蓝")) 0 0)

  ;; 设定drawable，前景，背景
  (let ((drawable (car (gimp-image-get-active-drawable img)))
	(Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(merged nil)
	(overlay nil))

    ;; 若非RGB，则将图像改为RGB模式
    (if (= (car (gimp-drawable-is-rgb drawable)) 0) (gimp-image-convert-rgb img))

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "相加")))
    (gimp-image-insert-layer img new 0 0)

    ;; 相加
    (gimp-layer-set-mode new 7)

    ;; 调色，蓝色加强

    (set! overlay (car (gimp-layer-new img
				       Width
				       Height
				       RGBA-IMAGE
				       "蓝调"
				       100
				       0)))
    (gimp-image-add-layer img overlay 1)

    (gimp-context-push)
    
    (gimp-context-set-background '(86 158 255))
    
    ;; 以背景色填充
    (gimp-edit-fill overlay 1)

    (gimp-layer-set-opacity overlay 60)

    (gimp-context-pop)

    (gimp-image-undo-group-end img))

  ;; 刷新显示
  (gimp-displays-flush))
(script-fu-register "script-fu-tiaose-lianglan"
		    "<Image>/调色/靓蓝"
		    "简单的靓蓝"
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)

(define (script-fu-tiaose-guangxiao img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 设定drawable，前景，背景
  (let ((drawable (car (gimp-image-get-active-drawable img)))
	(Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(merged nil)
	(overlay nil))

    ;; 光晕

    (set! overlay (car (gimp-layer-new img
				       Width
				       Height
				       RGBA-IMAGE
				       "光效"
				       100
				       OVERLAY-MODE)))
    (gimp-image-add-layer img overlay -1)

    (gimp-context-push)
    
    (gimp-context-set-foreground '(255 255 255))
    (gimp-context-set-background '(0 0 0))

    (gimp-edit-blend overlay 0 0 2 100 0 0 FALSE FALSE 0 0 TRUE
                     (/ Width 2)
		     (/ Height 2)
		     (- Width (/ Width 9))
		     (- Height (/ Height 9)))

    (gimp-context-pop)

    (gimp-image-undo-group-end img))

  ;; 刷新显示
  (gimp-displays-flush))
(script-fu-register "script-fu-tiaose-guangxiao"
		    "<Image>/调色/光效"
		    "简易的LOMO光效"
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)

(define (script-fu-tiaose-coffee img)

  (gimp-image-undo-group-start img)
  
  (script-fu-tiaose-hunhuang img)
  (script-fu-tiaose-jiangcai img)
  (let((new nil)
       (merged nil))
    
    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "柔光")))
    (gimp-image-insert-layer img new 0 0)

    ;; 柔光
    (gimp-layer-set-mode new 19)
    (gimp-layer-set-opacity new 36)

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "coffee")))
    (gimp-image-insert-layer img new 0 0)

    ;; 合并图层
    (set! merged (car (gimp-image-merge-down img new 0)))
    (set! merged (car (gimp-image-merge-down img merged 0)))
    (set! merged (car (gimp-image-merge-down img merged 0)))
    (gimp-item-set-name merged "咖啡"))
  (gimp-image-undo-group-end img))
(script-fu-register "script-fu-tiaose-coffee"
		    "<Image>/调色/咖啡"
		    "将图像的色彩调至咖啡."
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)

(define (script-fu-tiaose-hunhuang img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 盖印图层
  (gimp-image-insert-layer img (car (gimp-layer-new-from-visible img img "昏黄")) 0 0)

  ;; 设定
  (let ((drawable (car (gimp-image-get-active-drawable img)))
	(Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(merged nil))

    (gimp-context-push)

    (gimp-context-set-foreground '(255 144 0))

    ;; 若非RGB，则将图像改为RGB模式
    (if (= (car (gimp-drawable-is-rgb drawable)) 0) (gimp-image-convert-rgb img))

    ;; 降低饱和度
    (gimp-desaturate drawable)

    ;; 调色开始

    ;; 添加蒙版
    (gimp-layer-add-mask
     drawable
     (car (gimp-layer-create-mask drawable 5)))

    (set! new (car (gimp-layer-new img Width Height 0 "覆盖" 100 5)))
    (gimp-image-add-layer img new 0)

    ;; 以前景色填充
    (gimp-edit-fill new 0)

    ;; 合并图层
    (set! merged (car (gimp-image-merge-down img new 0)))

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "柔光")))
    (gimp-image-insert-layer img new 0 0)

    ;; 柔光
    (gimp-layer-set-mode new 19)

    ;; 盖印图层
    (set! new (car (gimp-layer-new-from-visible img img "昏黄")))
    (gimp-image-insert-layer img new 0 0)

    ;; 合并图层
    (set! merged (car (gimp-image-merge-down img new 0)))
    (set! merged (car (gimp-image-merge-down img merged 0)))

    (gimp-image-undo-group-end img)

    ;; 恢复调色板
    (gimp-context-pop))
  
  ;; 刷新显示
  (gimp-displays-flush))
(script-fu-register "script-fu-tiaose-hunhuang"
		    "<Image>/调色/昏黄"
		    "将图像的色彩调至昏黄."
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)

(define (script-fu-tiaose-shengwen img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 设定
  (let ((drawable (car (gimp-image-get-active-drawable img)))
	(Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(merged nil))

    (gimp-context-push)

    (gimp-context-set-foreground '(255 190 0))

    ;; 若非RGB，则将图像改为RGB模式
    (if (= (car (gimp-drawable-is-rgb drawable)) 0) (gimp-image-convert-rgb img))

    (set! new (car (gimp-layer-new img Width Height 0 "覆盖" 100 5)))
    (gimp-image-add-layer img new 0)

    (gimp-layer-set-opacity new 50)

    ;; 以背景色填充
    (gimp-edit-fill new 0)

    (gimp-image-undo-group-end img)

    ;; 恢复调色板
    (gimp-context-pop))
  
  ;; 刷新显示
  (gimp-displays-flush))
(script-fu-register "script-fu-tiaose-shengwen"
		    "<Image>/调色/色温/升温"
		    "升高图像温度。"
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)

(define (script-fu-tiaose-jiangwen img)

  (gimp-image-undo-group-start img)

  ;; 初始化

  ;; 设定
  (let ((drawable (car (gimp-image-get-active-drawable img)))
	(Height (car (gimp-image-height img)))
	(Width (car (gimp-image-width img)))
	(new nil)
	(merged nil))

    (gimp-context-push)

    (gimp-context-set-foreground '(0 65 255))

    ;; 若非RGB，则将图像改为RGB模式
    (if (= (car (gimp-drawable-is-rgb drawable)) 0) (gimp-image-convert-rgb img))

    (set! new (car (gimp-layer-new img Width Height 0 "覆盖" 100 5)))
    (gimp-image-add-layer img new 0)

    (gimp-layer-set-opacity new 50)

    ;; 以背景色填充
    (gimp-edit-fill new 0)

    (gimp-image-undo-group-end img)

    ;; 恢复调色板
    (gimp-context-pop))
  
  ;; 刷新显示
  (gimp-displays-flush))
(script-fu-register "script-fu-tiaose-jiangwen"
		    "<Image>/调色/色温/降温"
		    "降低图像温度。"
		    "Zeno Zeng <zenoes@qq.com>"
		    "Zeno Zeng"
		    "August 2012"
		    "*"
		    SF-IMAGE		"Image"			0)
