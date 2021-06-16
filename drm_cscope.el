;;;;
;;;; drm:cscope.el -- constructs cscope-master-info-table by selecting
;;;; files in drm:cscope-directories that match drm:cscope-regexp.
;;;;
;;;; Author: Dave Marquardt, marquard@austin.ibm.com
;;;;

(defvar drm:cscope-directories '("/afs/austin/aix/325/cscope")
  "*List of directories to search for cscope database files.
Each directory may also contain a prefix name which will be prefixed
to each of the files located in that directory and a relative prefix
to locate files from the database (this works around some cscope bugs).
For example:
	(setq drm:cscope-directories
	  \'(
	    \"/afs/austin/aix/325/cscope\"
	    (\"/afs/austin.ibm.com/aix/project/aix41J/cscope\" \"41j\")
	    (\"/afs/austin.ibm.com/aix/project/aix42Z/cscope\" \"42z\" 
             \"/afs/austin.ibm.com/aix/project/aix42Z\")
	  )
	)
The first directory /afs/austin/aix/325/cscope contains no prefix.
The second directory /afs/austin.ibm.com/aix/project/aix41J/cscope contains
the prefix 41j which will be prefixed to each file in that directory
to create a unique identification.
The third directory /afs/austin.ibm.com/aix/project/aix42Z/cscope contains
the prefix 42z and also a relative prefix
/afs/austin.ibm.com/aix/project/aix42Z."
)

(defvar drm:cscope-regexp ".*\\.db$\\|.*\\.out$"
  "*Regular expression to use to select files from directories in
drm:cscope-directories.")

(defvar drm:cscope-program "cscope"
  "*Name of cscope program.")

;;
;; set cscope-master-info-table by listing appropriate files from
;; /project/cscopes.
;;
(defun drm:set-cscope-table ()
  "Set cscope-master-info-table by reading information from files in
drm:cscope-directories whose filenames drm:cscope-regexp."
  (interactive nil)
  (setq cscope-master-info-table ())
  (let
      (
       (dirlist drm:cscope-directories)
       )
    (while (car dirlist)
      (let
	  (
	   (dirname (car dirlist))
	   (cscope_prefix)
	   (rel_prefix)
	   )
	(if (listp dirname)
	    (progn
	      (setq cscope_prefix (nth 1 dirname))
	      (setq rel_prefix (nth 2 dirname))
	      (setq dirname (nth 0 dirname))
	      )
	  )
	(if (not cscope_prefix)
	    (setq cscope_prefix "")
	  )
	(if (file-exists-p dirname)
	    (progn
	      (let
		  (
		   (files
		    (directory-files dirname nil drm:cscope-regexp)
		    )
		   )
		(while (car files)
		  (let
		      (
		       (pathname
			(concat dirname "/" (car files))
			)
		       )
		    (if (not rel_prefix)
			(condition-case ()
			    (progn
					; create the command line we
					; need to get the relative_prefix
			      (setq command
				    (concat "head -1 "
					    pathname
					    " | awk '{ print $3 }'"
					    )
				    )
					; run head -1 db | awk '{
					; print $3 }' to get the
					; relative_prefix into the
					; " drm:cscope-temp" buffer
			      (call-process
			       "sh" nil 
			       (get-buffer-create " drm:cscope-temp")
			       nil "-c" command)
					; extract relative_prefix from
					; " drm:cscope-temp" into relative_prefix
			      (set-buffer " drm:cscope-temp")
			      (setq relative_prefix
				    (buffer-substring
				     (point-min) (1-(point-max))
				     )
				    ) 
					; kill " drm:cscope-temp" buffer
			      (kill-buffer " drm:cscope-temp")
			      )
			  (error
			   (progn
			     (message "Incomplete cscope file %s" pathname)
			     (sit-for 2)
			     (setq files (cdr files))
			     )
			   )
			  )
		      (setq relative_prefix rel_prefix)
		      )
		    (setq cscope-master-info-table
			  (append cscope-master-info-table
				  (list
				   (list
				    (setq cscope_name
					  (concat
					   cscope_prefix
					   (car files)
					   )
					  )
				    (list
				     drm:cscope-program "-l" "-d" "-f"
				     pathname
				     )
				    nil
				    relative_prefix
				    )
				   )
				  )
			  )
		    (setq files (cdr files))
		    )
		  )
		)
	      )
	  )
	)
      (setq dirlist (cdr dirlist))
      )
    )
  )

;;
;; Prompt the user for a valid cscope ID.
;;
(defun drm:set-cscope-id ()
  "Set a buffer's cscope-id."
  (interactive nil)
  ;
  ; construct the list that we pass in to completing-read
  ;
  (let
      (
       (tablecopy cscope-master-info-table)
       (counter 1)
       (ids nil)
       )
    (while (car tablecopy)
      (setq ids
	    (append ids
		    (list
		     (list
		      (car
		       (car tablecopy)
		       )
		      counter
		      )
		     )
		    )
	    )
      (setq tablecopy (cdr tablecopy))
      (setq counter (1+ counter))
      )
    ;
    ; Now we have a copy of the table, so we can call completing-read
    ;
    (setq cscope-id
	  (completing-read "Cscope ID: " ids)
	  )
    )
  )
