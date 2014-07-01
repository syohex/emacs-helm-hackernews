;;; helm-hackernews.el --- helm interface of hackernews.el

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-helm-hackernews
;; Version: 0.01
;; Package-Requires: ((helm "1.0") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'cl-lib)

(require 'helm)
(require 'json)
(require 'browse-url)

(defgroup helm-hackernews nil
  "hacker news with helm interface"
  :group 'hackernews)

(defface helm-hackernews-title
  '((((class color) (background light))
     :foreground "red" :weight semi-bold)
    (((class color) (background dark))
     :foreground "green" :weight semi-bold))
  "face of post title"
  :group 'helm-hackernews)

(defvar helm-hackernews-url "http://api.ihackernews.com/page")

(defun helm-hackernews-get-posts ()
  (with-temp-buffer
    (unless (zerop (call-process "curl" nil t nil "-s" helm-hackernews-url))
      (error "Failed: 'curl -s %s'" helm-hackernews-url))
    (let* ((json nil)
           (ret (ignore-errors
                  (setq json (json-read-from-string
                              (buffer-substring-no-properties
                               (point-min) (point-max))))
                  t)))
      (unless ret
        (error "Error: Can't get JSON response"))
      json)))

(defun helm-hackernews-sort-predicate (a b)
  (let ((points-a (plist-get (cdr a) :points))
        (points-b (plist-get (cdr b) :points)))
    (> points-a points-b)))

(defun helm-hackernews-init ()
  (let ((json-res (helm-hackernews-get-posts)))
    (sort (cl-loop with posts = (assoc-default 'items json-res)
                   for post across posts
                   for points = (assoc-default 'points post)
                   for title = (assoc-default 'title post)
                   for url = (assoc-default 'url post)
                   for comments = (assoc-default 'commentCount post)
                   for id = (assoc-default 'id post)
                   for cand = (format "%s %s (%d comments)"
                                      (format "[%d]" points)
                                      (propertize title 'face 'helm-hackernews-title)
                                      comments)
                   collect
                   (cons cand
                         (list :url url :points points
                               :post-url (format "https://news.ycombinator.com/item?id=%s" id))))
          'helm-hackernews-sort-predicate)))

(defun helm-hackernews-browse-link (cand)
  (browse-url (plist-get cand :url)))

(defun helm-hackernews-browse-post-page (cast)
  (browse-url (plist-get cast :post-url)))

(defvar helm-hackernews-source
  '((name . "Hacker News")
    (candidates . helm-hackernews-init)
    (action . (("Browse Link" . helm-hackernews-browse-link)
               ("Browse Post Page"  . helm-hackernews-browse-post-page)))
    (candidate-number-limit . 9999)))

;;;###autoload
(defun helm-hackernews ()
  (interactive)
  (helm :sources '(helm-hackernews-source) :buffer "*helm-hackernews*"))

(provide 'helm-hackernews)

;;; helm-hackernews.el ends here
