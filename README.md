# collectionview-a11y-reload-bug

To quickly repro the bug, used this project as a base https://www.raywenderlich.com/18895088-uicollectionview-tutorial-getting-started

For this example, selecting a cell calls reload. Thus selecting a cell in VO (i.e. first VO focus a cell, then double tap), will show the reloading bug.

The bug is that:
1) reload causes VO announcements to happen for the VO focused cells, it should not make any announcement during reload.
2) two cells are announced, the first is nearly always the wrong cell, the second is the correctly last focused cell. In a more complex case (where data changes more significantly) the second cell can be incorrect also.

This is what happens during a reload:
https://user-images.githubusercontent.com/72810910/122247047-12746900-ce95-11eb-8ae6-da96a82f9e32.MOV
