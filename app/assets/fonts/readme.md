The icon font is generated at fontello.

To recreate the icon font and add to it (recommended method):
0. At https://fontello.com upload the existing icons.svg from this directory
1. Select the characters/images in the Custom Icons section
2. Add new characters/images
3. Rename the font "icons"
4. Click 'Download webfont' button (zip file)
5. From the zipped file, copy the fonts files (eot, svg, ttf, woff) to the /app/assets/fonts directory, replacing the files already there
6. From the zip file's css/icons-embedded.css, copy the second @font-face declaration (with the data url) into /app/assets/stylesheets/application/vendor/icons_embedded.scss
6. From the zip file's css/icons-embedded.css, in the font-face declaration at the top of the file, copy the url variable from one of the font file paths, e.g. 'emfcbl'
7. In the stylesheet (/app/assets/stylesheets/application/vendor/icons.scss) font-face declaration, paste in the new url variable in each font file path
8. From the zip file's css/icon-codes.css, copy all of the css declarations
9. In the stylesheet (/app/assets/stylesheets/application/_settings/_icons.scss), update the list of icon contents with the new version.
10. Make sure you update app/views/style_guide/icon_font.haml with any icons you add

To view all of the icons currently in use in the app, in development or on staging, view /style_guide/icon_font

The icons are listed in the scss file and in the style guide in the order they appear in icomoon, so it's helpful for future generation to keep them in the same order, and to update the style guide page when new icons are added.
