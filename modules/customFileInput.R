# nolint start

customFileInput <- function(inputId, ...) {
  el <- fileInput(inputId, ...)

  tagQ <- htmltools::tagQuery(el)

  tagQ$
    find(sprintf("input#%s", inputId))$
    removeAttrs("style")$
    addAttrs(
    style = "
        position: absolute !important;
        overflow: hidden;
        clip: rect(0 0 0 0);
        height: 1px;
        width: 1px;
        margin: -1px;
        padding: 0;
        border: 0;
      "
  )$
    allTags()
}

htmltools::browsable(customFileInput("foo", "My Foo"))

# nolint end
