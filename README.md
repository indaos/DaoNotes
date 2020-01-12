# DaoNotes

This application is for managing notes and various widgets inside them. This project is an attempt to test SwiftUI how efficient it is to use. This is the demo project.
Although this application is mainly intended for experiments, it implements all the basic necessary functionality of such  applications.

* rich text format
* folders and subfolders
* storing images in notes
* adding tables
* password protected notes
* using of OCR when adding images with text 
* search by notes
* storing notes only locally
* storing notes in iCloud and sync them with local
* sharing individual notes for individual users

### Menu
It turned out that scrolling and animating menus can be implemented using pure SwiftUI

<p align="center">
  <img src="menu.gif"  width="240" height="500" >
</p>
<br/>
<br/>
<br/>

### Editing notes
Editing notes is implemented by extending the UITextView and using it through the UIViewRepresentable

<p align="center">
  <img src="edit_note.gif"  width="240" height="500" >
</p>
<br/>
<br/>
<br/>

### Various elements
Different widgets can be easily integrated using the wrapper UIViewRepresentable

<p align="center">
  <img src="edit_misc.gif"  width="240" height="500" >
    <img src="edit_misc2.gif"  width="240" height="500" >

</p>
<br/>
<br/>
<br/>

### iCloud
Notes can be stored locally or in iCloud (implemented simple synchronization). They can also be individually shared with other users. If changes have occurred in the notes, a push notification will be received.

<p align="center">
  <img src="icloud.gif"  width="240" height="500" >
</p>
<br/>
<br/>
<br/>

### Settings
The app also supports customizing the colors of menus and buttons and other simple settings.

<p align="center">
  <img src="colors.gif"  width="240" height="500" >
</p>


