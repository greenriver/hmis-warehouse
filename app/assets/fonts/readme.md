The icon font is generated at icomoon, using their free service.
To add fonts to the package, you can either re-create the font collection and add to it, or create an additional icon set with only the new icons and include that in the site as well.

To recreate the icon font and add to it (recommended method):
0. At https://icomoon.io/app/#/select choose (hamburger -> Deselect) to reset the selection
1. Select the characters/images already used in this site (see: /style_guide/icon_font)
2. Add new characters/images
3. Click 'generate font' button
4. Click 'Download' button (zip file)
5. From the zipped file, copy the fonts files (eot, svg, ttf, woff) to the /app/assets/fonts directory, replacing the files already there
6. From the zip file's style.css, in the font-face declaration at the top of the file, copy the url variable from one of the font file paths, e.g. 'emfcbl' 
7. In the stylesheet (/app/assets/stylesheets/vendor/icomoon.scss) font-face declaration, paste in the new url variable in each font file path
8. From the zip file's style.css, copy all of the css declarations
9. In the stylesheet (/app/assets/stylesheets/vendor/icomoon.scss), paste over all of the css declarations. The icons are listed in the scss file in the order they appear in icomoon, so it's helpful for future generation to keep them in the same order.
10. Make sure you update app/views/style_guide/icon_font.haml with any icons you add

To view all of the icons currently in use in the app, in development or on staging, view /style_guide/icon_font

The icons are listed in the scss file and in the style guide in the order they appear in icomoon, so it's helpful for future generation to keep them in the same order, and to update the style guide page when new icons are added.