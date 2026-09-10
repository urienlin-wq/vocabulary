# Word Memorizer App - GitHub Upload Guide

## What changed in this version
All string concatenation now uses the + operator instead of the ${} interpolation
syntax, and line-splitting uses LineSplitter() instead of split('\n'). This avoids
the mobile clipboard/autocorrect issues that were breaking the build (curly quotes,
literal newlines replacing \n, etc).

## How to upload this to GitHub (avoids manual copy-paste entirely)

1. Go to your repository on GitHub (English-learning-app)
2. Delete the old lib folder entirely: open each file inside lib/, use the trash
   icon to delete it, commit each deletion. (Or just overwrite each file with the
   new content below - either works.)
3. Click "Add file" -> "Upload files"
4. On your phone, tap "choose your files" and select ALL the files from this
   package (keeping the same folder structure: lib/screens/, lib/services/,
   lib/models/, plus pubspec.yaml and codemagic.yaml in the root)
5. GitHub's upload interface preserves folder structure automatically if your
   phone's file picker uploads a folder, or you can upload file by file into the
   matching path.
6. Commit the upload.

Uploading raw files (instead of copy-pasting text into the browser editor)
completely avoids the autocorrect/smart-punctuation problem, because the file
bytes are transferred as-is.

## After upload

1. Go back to Codemagic, click "Start new build"
2. Select "Android Build" as the workflow, "main" as the branch
3. Wait for the build (5-15 minutes)
4. Download the APK from the Artifacts section
5. Install it on your phone
