;;; LALAs for GIMP 2.8 -- LALAs's Advanced Line Art script.

;; This is mostly based on Lasm <lasm@rocketmail.com>'s Advanced Line Art script.
;; I (Zeno Zeng) modefied it for myself.  My mistakes are my own.

;; Time-stamp: <2012-08-12 14:07:41>

;; Tags: artistic

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.




;;;  Instructions on using this script


;; 1. The pre-processing water boiler is used to lighten the final image and produce
;;     a more refined, smooth line in the line-art. The default value of 80 degC means no
;;     pre-processing smoothing operation is carried out. Each susbsequent temperature greater
;;     than 80 degC produces stronger smoothing effect.This option is useful for "Java"
;;     and "Capuccino" coffee as they tend to produce very dark images.
;; 2. Conversely, the post-processing Decaffienator produces darker final image. It is an
;;     operation carried out after flattening all visible layers in the image. Use it if the final image
;;     is too light. This is particularly useful for the light, creamy Latte coffee, but all coffee   ;     types will benefit from it as well.
;; 3. Texture can be turned off for certain images, which is better off without it. Similarly for
;;     polychromatic option.
;; 4. Polychromatic and line-art color are mutually exclusive options. To change line art color
;;     from blue to something else, simply click on the line art color bar and select the color
;;     you want. For black color, all sliders in the color selector should have zero value
;; 5. Very colorful line-art is often produced by turning on polychromatic and turning off texture.
;; 6. Use flatten option when you are satisfied with the result or turn it off if you want to experiment
;;     with the layers.
;; 7. The automatic adjustment is useful most of the time, so leave it as it is, unless your
;;     image needs manual adjustment for lightness/contrast etc.
;; 8. Java and Capuccino styles tend to take longer to produce as they use the Gimpressionist
;;     plugin. Expresso appears to give reasonably good results most of the time.

;; That's all folks. Have fun with this script !
;; Another Grandmother Coffee House production.


;; Set register common information
(define SCRIPT-FU-LINE-ART-CHOICE1    (list _"Automatic" _"Manual"))
(define SCRIPT-FU-LINE-ART-CHOICE2    (list _"Java" _"Capuccino" _"Expresso" _"Mocha" _"Simple" _"Simple Color"))
(define SCRIPT-FU-LINE-ART-CHOICE3    (list _"80 deg C" _"85 deg C" _"90 deg C" _"95 deg C"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Advanced Line Art  function:

;; Requires:
;;   plug-in-sobel
;;   plug-in-gauss-rle
;;   plug-in-gimpressionist
;;   plug-in-dilate
;;   plug-in-convmatrix

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (script-fu-line-art img inLayer tempmode ppdecaf? texture? polychrome? art-color stmode opmode brightness contrast lightness saturation)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;  Helper function to create names of Coffee Beans and blending options
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define flatten? FALSE)

  ;; fix for only one layer
  (when (= (car (gimp-image-get-layers img)) 1)
      (set! inLayer (car (gimp-layer-new-from-visible img img "Ori")))
      (gimp-image-insert-layer img inLayer  0 0))

  (define (coffee-name stmode tempmode texture? polychrome? art-color ppdecaf? opmode brightness contrast lightness saturation)
    (define brt (number->string brightness 10))
    (define crt (number->string contrast 10))
    (define ltn (number->string lightness 10))
    (define stn (number->string saturation 10))
    (define bcls (string-append "-adj" "(" brt "," crt "," ltn "," stn ")"))
    (define r (number->string(car art-color)))
    (define g (number->string(cadr art-color)))
    (define b (number->string(caddr art-color)))
    (define rgb (string-append "-c" "(" r "," g "," b ")"))
    (string-append
     (cond
      ((= stmode 0) _"Java")
      ((= stmode 1) _"Capuccino")
      ((= stmode 2) _"Expresso")
      ((= stmode 3) _"Mocha")
      ((= stmode 4) _"Latte"))
     (cond
      ((= tempmode 0) "")
      ((= tempmode 1) _"-85 degC")
      ((= tempmode 2) _"-90 degC")
      ((= tempmode 3) _"-95 degC"))
     (if  (= opmode 1)
	  bcls
	  "")
     (if  (eqv? texture? TRUE)
	  _"-texture" "")
     (if  (eqv? polychrome? TRUE)
	  _"-polychrome"
	  rgb)
     (if  (eqv? ppdecaf? TRUE)
	  _"-Decaf" "")
     )
    )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;  Helper function to create a new layer
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (copylayer layer layername)
    (let* (
	   (new (car(gimp-layer-copy layer 1)))) ; Add an alpha channel
      (gimp-drawable-set-name new layername)
      new
      )
    )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;  Helper function to return matrix array
					;  with thanks to Iccii script
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (get-matrix matrix-list)
    (define (list-ref l n) (nth n l))
    (let* ((count 0)
	   (matrix (cons-array 25 'double)))
      (while (< count 25)
	     (aset matrix count (list-ref matrix-list count))
	     (set! count (+ count 1)))
      matrix)) ; Return the matrix array

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;  Helper function to return channels array
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (get-channels drawable gray? red? green? blue? alpha?)
    (let* ((channels (cons-array 5 'long))
	   (gray 0)
	   (red 0)
	   (green 0)
	   (blue 0)
	   (alpha 0)
	   )
      (if (eqv? (car (gimp-drawable-is-gray drawable)) TRUE)
	  (set! gray (if (eqv? gray? TRUE) 1 0))
	  (set! gray 0))
      (if (eqv? (car (gimp-drawable-is-rgb drawable)) TRUE)
	  (begin
	    (set! red   (if (eqv? red?   TRUE) 1 0))
	    (set! green (if (eqv? green? TRUE) 1 0))
	    (set! blue  (if (eqv? blue?  TRUE) 1 0)))
	  (begin
	    (set! red   0)
	    (set! green 0)
	    (set! blue  0)))
      (if (eqv? (car (gimp-drawable-has-alpha drawable)) TRUE)
	  (set! alpha   (if (eqv? alpha? TRUE) 1 0))
	  (set! alpha   0))
      (aset channels 0 gray)
      (aset channels 1 red)
      (aset channels 2 green)
      (aset channels 3 blue)
      (aset channels 4 alpha)
      channels)) ; Return the channel array

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
					;  Main function
					;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define matrix-list                                               ; prepare pre-processing water
    (list   0   0   0   0   0
	    0   1   2   1   0
	    0   2   4   2   0
	    0   1   2   1   0
	    0   0   0   0   0))
  (define channels                                                 ; prepare smooth boiling water
    (list   0   1   1   1   0))
  (let*
      (
       (width (car (gimp-drawable-width inLayer)))
       (height (car (gimp-drawable-height inLayer)))
       (color-layer (car (gimp-layer-new img width height RGBA-IMAGE _"Color Line Art" 100 NORMAL-MODE)))
       (bg-layer (copylayer inLayer _"White Layer"))
       (grey-layer (copylayer bg-layer _"Grey Layer"))
       (sobel-layer (copylayer grey-layer _"Sobel Layer"))
       (impress-layer (copylayer sobel-layer _"Saturation Layer"))
       (black-layer (copylayer impress-layer _"Black Line Art"))
       (old-fg (car (gimp-context-get-foreground)))
       (old-bg (car (gimp-context-get-background)))
       (index 0)
       (capuccino-layer 0)
       (sobel-layer1 0)
       (sobel-layer2 0)
       (sobel-layer3 0)
       (sobel-layer4 0)
       (latte-layer 0)
       (latte-layer1 0)
       (latte-layer2 0)
       (coffee-layer 0)
       (coffee-layer1 0)
       (coffee-layer2 0)

       )

    (gimp-image-undo-group-start img)

    ;; Real work goes in here

    (gimp-image-add-layer img bg-layer -1)
    (gimp-image-set-active-layer img bg-layer)
    (gimp-edit-fill bg-layer WHITE-IMAGE-FILL)
    (if  (= opmode  0)
	 (begin
	   (gimp-image-add-layer img grey-layer -1)
	   (gimp-context-set-background '(128 128 128))
	   (gimp-edit-fill grey-layer 1)                      ;  Grey Layer fill
	   (gimp-layer-set-mode grey-layer ADDITION-MODE)     ;   Addition Layer Mode
	   (gimp-image-add-layer img sobel-layer -1)
	   (if  (> tempmode 0)
		(begin
		  (let* ((matrix (get-matrix matrix-list))
			 (channels (get-channels sobel-layer FALSE TRUE TRUE TRUE FALSE)))
		    (set! index 0)
		    (while (<  index tempmode)
			   (plug-in-convmatrix 1 img sobel-layer 25 matrix TRUE      ;;  thanks to Iccii script
					       16 0 5 channels 0)
			   (set! index (+ index 1))))
		  ))
	   (gimp-brightness-contrast sobel-layer 10 -9)
	   (gimp-image-set-active-layer img grey-layer)
	   (gimp-image-merge-down img grey-layer  EXPAND-AS-NECESSARY)))
    (if  (= opmode  1)
	 (begin
	   (gimp-image-add-layer img sobel-layer -1)
	   (if  (> tempmode 0)
		(begin
		  (let* ((matrix (get-matrix matrix-list))
			 (channels (get-channels sobel-layer FALSE TRUE TRUE TRUE FALSE)))
		    (set! index 0)
		    (while (<  index tempmode)
			   (plug-in-convmatrix 1 img sobel-layer 25 matrix TRUE      ;;  thanks to Iccii script
					       16 0 5 channels 0)
			   (set! index (+ index 1))))
		  ))
	   (gimp-brightness-contrast sobel-layer brightness contrast)
	   (gimp-hue-saturation sobel-layer 0 0 lightness saturation)))
    (gimp-image-set-active-layer img sobel-layer)
    (plug-in-sobel 1 img sobel-layer TRUE TRUE TRUE)

    (if  (= stmode 1)                                                                      ;  Capuccino - 5 spoons of steamed milk please
	 (begin
	   (set! capuccino-layer (car (gimp-image-merge-down img sobel-layer  EXPAND-AS-NECESSARY)))
	   (set! sobel-layer1 (copylayer capuccino-layer _"Sobel Layer 1"))
	   (gimp-image-add-layer img sobel-layer1 -1)
	   (plug-in-gauss-rle 1 img sobel-layer1 5 TRUE TRUE)
	   (gimp-layer-set-mode sobel-layer1 SCREEN-MODE)      ; Screen Layer Mode
	   (set! sobel-layer2 (copylayer sobel-layer1 _"Sobel Layer 2"))
	   (gimp-image-add-layer img sobel-layer2 -1)
	   (set! sobel-layer3 (copylayer sobel-layer2 _"Sobel Layer 3"))
	   (gimp-image-add-layer img sobel-layer3 -1)
	   (set! sobel-layer4 (copylayer sobel-layer3 _"Sobel Layer 4"))
	   (gimp-image-add-layer img sobel-layer4 -1)))

    (if  (and  (<= stmode 1)
	       (if  (eqv? texture? TRUE)                                                        ; slow art brewing, go for a long Java coffee break
		    (begin
		      (gimp-image-add-layer img impress-layer -1)
		      (gimp-image-set-active-layer img impress-layer)
		      (gimp-brightness-contrast impress-layer brightness contrast)
		      (plug-in-gimpressionist 0 img impress-layer _"Crosshatch") ; impressionist cannot run in non-interactive mode yet
		      (gimp-layer-set-mode impress-layer SATURATION-MODE)))   ; Saturation Layer Mode
	       )          ; end of  (and
	 )

    (if  (> stmode 1)                                                                           ; expresso coffee - instant art gratification
	 (begin
	   (gimp-image-set-active-layer img sobel-layer)
	   (gimp-layer-set-mode sobel-layer DIFFERENCE-MODE)     ; Difference Layer Mode
	   (set! sobel-layer1 (copylayer sobel-layer _"Sobel Layer 1"))
	   (gimp-image-add-layer img sobel-layer1 -1)
	   (gimp-layer-set-mode sobel-layer1 DIFFERENCE-MODE)   ; Difference Layer Mode
	   (set! sobel-layer2 (copylayer sobel-layer1 _"Sobel Layer 2"))
	   (gimp-image-add-layer img sobel-layer2 -1)
	   (gimp-layer-set-mode sobel-layer2 DIFFERENCE-MODE)   ; Difference Layer Mode
	   (gimp-drawable-set-visible inLayer FALSE)

	   (if  (> stmode 2) 
		(begin
		  (set! latte-layer (car (gimp-image-merge-visible-layers img EXPAND-AS-NECESSARY)))
		  (gimp-desaturate latte-layer)
		  (gimp-levels latte-layer VALUE-LUT 128 255 1 0 255)))

	   (if  (> stmode 3)                                                                       ; latte coffee - with a little skimmed milk
		(begin
		  (set! latte-layer1 (copylayer latte-layer _"Latte Layer 1"))
		  (gimp-image-add-layer img latte-layer1 -1)
		  (plug-in-gauss-rle 1 img latte-layer1 5 TRUE TRUE)
		  (gimp-layer-set-mode latte-layer1 MULTIPLY-MODE)    ; Multiply Layer Mode
		  (set! latte-layer2 (copylayer latte-layer1 _"Latte Layer 2"))
		  (gimp-image-add-layer img latte-layer2 -1)
		  (plug-in-gauss-rle 1 img latte-layer2 10 TRUE TRUE)
		  (gimp-layer-set-mode latte-layer2 SCREEN-MODE)))    ; Screen Layer Mode

	   (if  (eqv? texture? TRUE)
		(begin
		  (gimp-image-add-layer img impress-layer -1)
		  (gimp-layer-set-mode impress-layer SATURATION-MODE)    ; Saturation Layer Mode
		  )
		)
	   (gimp-drawable-set-visible inLayer TRUE)))  ; end of  expresso coffee (if  (> stmode 1)

    (gimp-image-add-layer img black-layer -1)
    (gimp-image-set-active-layer img black-layer)
    (gimp-context-set-background '(0 0 0))
    (gimp-edit-fill black-layer BG-IMAGE-FILL)                          ; Black Line Art
    (gimp-layer-set-mode black-layer COLOR-MODE)            ; Color Layer Mode

    (gimp-image-add-layer img color-layer -1)
    (gimp-image-set-active-layer img color-layer)
    (gimp-context-set-foreground art-color)
    (gimp-edit-fill color-layer FG-IMAGE-FILL)                           ; Color Line Art
    (gimp-layer-set-mode color-layer COLOR-MODE)            ; Color Layer Mode

    (if  (eqv? polychrome? TRUE)
	 (begin
	   (gimp-layer-add-alpha inLayer)
	   (gimp-image-raise-layer-to-top img inLayer)
	   (gimp-layer-set-mode inLayer COLOR-MODE)))               ; Color Layer Mode

    (if  (or (eqv? flatten? TRUE)
	     (eqv? ppdecaf? TRUE))                      ; Post processing coffee decaffeinator requires flatten mode
	 (begin
	   (set! coffee-layer (car (gimp-image-flatten img)))
	   (gimp-drawable-set-name coffee-layer (coffee-name stmode tempmode texture? polychrome? art-color ppdecaf? opmode brightness contrast lightness saturation))
	   (if  (eqv? ppdecaf? TRUE)
		(begin
		  (set! coffee-layer1 (copylayer coffee-layer _"Coffee Layer 1"))
		  (gimp-image-add-layer img coffee-layer1 -1)
		  (gimp-layer-set-mode coffee-layer1 MULTIPLY-MODE)    ; Multiply Layer Mode
		  (set! coffee-layer2 (copylayer coffee-layer1 _"Coffee Layer 1"))
		  (gimp-image-add-layer img coffee-layer2 -1)
		  (set! coffee-layer (car (gimp-image-flatten img)))
		  (gimp-drawable-set-name coffee-layer (coffee-name stmode tempmode texture? polychrome? art-color ppdecaf? opmode brightness contrast lightness saturation))
		  (if (defined? 'plug-in-dilate)
		      ()
		      (plug-in-dilate 1 img coffee-layer 1 HISTOGRAM-VALUE 1.0 7 0 255))
		  ))
	   )
	 )


    ;; Zeno

    (when  (= stmode 3)
	   (gimp-layer-set-mode inLayer 13)
	   (gimp-layer-set-opacity inLayer 50))

    (when  (= stmode 4)
	   ;; 颜色
	   (gimp-layer-set-mode inLayer 13)
	   (gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "Saturation Layer"))))

    (when  (= stmode 5)
	   ;; 增益合并
	   (gimp-layer-set-mode inLayer 21)
	   ;; 高斯模糊
	   (plug-in-gauss-rle 1 img inLayer 5 5 5)
	   ;; 不透明度
	   (gimp-layer-set-opacity inLayer 60)
	   ;; 移去无用图层
	   (gimp-image-remove-layer img (car (gimp-image-get-layer-by-name img "Saturation Layer"))))


    (gimp-image-undo-group-end img)
    (gimp-displays-flush)

    (gimp-context-set-background old-bg)
    (gimp-context-set-foreground old-fg)

    )
  )

(script-fu-register
 "script-fu-line-art"
 _"<Image>/艺术/LALAs"
 "Lasm's famous Line Art effect for photographs. (Version 3.5) This works on any RGB image.\nThe technique may not be effective when used on images with large areas of high saturation.\nThe default values adjust for that. If the image is too dark, you may want to adjust brightness/contrast values only slightly before starting the script.\nTip: If you do not have a good Gimpressionist preset, simply hit cancel at the Gimpressionist dialog window, and you will still get a good greyscale line-art."
 "lasm"
 "Copyright 2001-2005, lasm"
 "March 12, 2001"
 "RGB*"
 SF-IMAGE              "The Image"        0
 SF-DRAWABLE             "The Layer"       0
 SF-OPTION           _"Water Temperature" SCRIPT-FU-LINE-ART-CHOICE3
 SF-TOGGLE           _"Post Processing Decaffeinator"          FALSE
 SF-TOGGLE           _"Texture"           TRUE
 SF-TOGGLE           _"Polychromatic"    FALSE
 SF-COLOR             _"Line Art Color"  '(220 219 219)  ;220 219 219
 SF-OPTION           _"Art Style"         SCRIPT-FU-LINE-ART-CHOICE2
 SF-OPTION           _"Adjustment"        SCRIPT-FU-LINE-ART-CHOICE1
 SF-ADJUSTMENT _"Brightness"             '(10 -127 127 1 10 0 0)
 SF-ADJUSTMENT _"Contrast"               '(-9 -127 127 1 10 0 0)
 SF-ADJUSTMENT _"Lightness"              '(100 -100 100 1 10 0 0)
 SF-ADJUSTMENT _"Saturation"             '(-70 -100 100 1 10 0 0)
 )
