#' Generates a syntactically-correct R name based on a SAGA-GIS identifier
#'
#' SAGA-GIS identifiers sometimes cannot represent syntactically-correct names
#' in R because they start with numbers or have spaces. They are also all in
#' uppercase which is ugly to refer to in code. This function creates an
#' alternative/alias identifier.
#'
#' @param identifier A character with the identifier.
#'
#' @return A character with a syntactically-correct alias.
#'
#' @keywords internal
create_alias <- function(identifier) {
  alias <- identifier

  if (grepl("^[[:digit:]]", identifier)) {
    alias <- paste0("x", identifier)
  }

  alias <- gsub(" ", "_", alias)
  alias <- tolower(alias)
  alias <- make.names(alias, unique = TRUE)

  alias
}


#' Generates a list of `parameter` objects for a SAGA-GIS tool
#'
#' Each `parameter` object contains information about the datatype, permissible
#' values and input/output settings associated with each identifier for a
#' SAGA-GIS tool.
#'
#' @param tool_options A data.frame containing the table that refers to the
#'   SAGA-GIS tool parameter options.
#'
#' @return A `parameters` object
#'
#' @keywords internal
parameters <- function(tool_options) {

  # replace tool arguments with syntactically-correct version
  tool_identifiers <- tool_options$Identifier
  tool_aliases <- sapply(tool_identifiers, create_alias)
  tool_aliases <- make.names(tool_aliases, unique = TRUE)

  # convert options table to nested list
  params <- rep(list(NA), nrow(tool_options))
  params <- stats::setNames(params, tool_aliases)

  for (i in seq_len(length(tool_aliases))) {
    alias <- tool_aliases[[i]]
    identifier <- tool_identifiers[[i]]

    params[[alias]] <- parameter(
      type = tool_options[tool_options$Identifier == identifier, ][["Type"]],
      name = tool_options[tool_options$Identifier == identifier, ][["Name"]],
      alias = alias,
      identifier = identifier,
      description = tool_options[tool_options$Identifier == identifier, ][["Description"]],
      constraints = tool_options[tool_options$Identifier == identifier, ][["Constraints"]]
    )
  }

  class(params) <- "parameters"
  params
}


#' Parameter class
#'
#' Stores metadata associated with each SAGA-GIS tool parameter.
#'
#' @param type A character to describe the data type of the parameter. One of
#'   "input", "output", "Grid", "Grid list", "Shapes", "Shapes list", "Table",
#'   "Static table", "Table list", "File path", "field", "Integer", "Choice",
#'   "Floating point", "Boolean", "Long text", "Text.
#' @param name A character with the long name of the parameter.
#' @param alias A syntactically correct alias for the identifier.
#' @param identifier A character with the identifier of the parameter used by
#'   saga_cmd.
#' @param description A character with the description of the parameter.
#' @param constraints A character describing the parameters constraints.
#'
#' @return A `parameter` class object.
#'
#' @keywords internal
parameter <-
  function(type,
           name,
           alias,
           identifier,
           description,
           constraints) {

    # parameter class attributes
    param <- list(
      type = tolower(type),
      name = name,
      alias = identifier,
      identifier = identifier,
      description = stringr::str_to_sentence(description),
      constraints = constraints,
      io = NA,
      feature = NA,
      default = NA,
      minimum = NA,
      maximum = NA,
      value = NULL,
      files = NULL
    )

    # strip empty values
    for (key in names(param)) {
      param[[key]] <- param[[key]][1]
    }

    # generate syntactically-correct alias for identifier
    if (grepl("^[[:digit:]]", identifier)) {
      param$alias <- paste0("x", identifier)
    }

    param$alias <- gsub(" ", "_", param$alias)
    param$alias <- tolower(param$alias)
    param$alias <- make.names(param$alias, unique = TRUE)

    param$description <- ifelse(
      param$description == "",
      NA_character_,
      param$description
    )

    # parse constraints into default, minimum, and maximum attributes
    param$constraints <-
      stringr::str_remove_all(param$constraints, "Available Choices:")

    param$constraints <-
      stringr::str_remove_all(param$constraints, "^\n")

    param$constraints <-
      stringr::str_replace_all(param$constraints, "\n", ";")

    param$default <-
      stringr::str_extract(param$constraints, "(?<=Default: \\s{0,1})[-0-9.]+")

    param$default <-
      suppressWarnings(as.numeric(param$default))

    param$minimum <-
      stringr::str_extract(param$constraints, "(?<=Minimum: \\s{0,1})[-0-9.]+")

    param$minimum <-
      suppressWarnings(as.numeric(param$minimum))

    param$maximum <-
      stringr::str_extract(param$constraints, "(?<=Maximum: \\s{0,1})[-0-9.]+")

    param$maximum <-
      suppressWarnings(as.numeric(param$maximum))

    # convert constraints into lists
    param$constraints <-
      stringr::str_split(param$constraints, "Default: ")[[1]][1]

    if (param$constraints == "") {
      param$constraints <- NA_character_
    }

    if (!is.na(param$constraints)) {
      param$constraints <-
        stringr::str_split(param$constraints, "\\[[:digit:]\\]")[[1]]
      param$constraints <- param$constraints[param$constraints != ""]
      param$constraints <- stringr::str_trim(param$constraints)
      param$constraints <- paste(
        paste0("[", seq_along(param$constraints) - 1, "]"),
        param$constraints
      )
    }

    # parse type into explicit `io` attribute
    if (stringr::str_detect(param$type, "input")) {
      param$io <- "Input"
    }

    if (stringr::str_detect(param$type, "output")) {
      param$io <- "Output"
    }

    if (stringr::str_detect(param$type, "grid")) {
      param$feature <- "Grid"
    }

    if (stringr::str_detect(param$type, "grid list")) {
      param$feature <- "Grid list"
    }

    if (stringr::str_detect(param$type, "shapes")) {
      param$feature <- "Shape"
    }

    if (stringr::str_detect(param$type, "shapes list")) {
      param$feature <- "Shapes list"
    }

    if (stringr::str_detect(param$type, "table")) {
      param$feature <- "Table"
    }

    if (stringr::str_detect(param$type, "static table")) {
      param$feature <- "Table"
    }

    if (stringr::str_detect(param$type, "table list")) {
      param$feature <- "Table list"
    }

    if (stringr::str_detect(param$type, "file path")) {
      param$feature <- "File path"
    }

    if (stringr::str_detect(param$type, "field")) {
      param$feature <- "Table field"
    }

    if (stringr::str_detect(param$type, "integer")) {
      param$feature <- "Integer"
    }

    if (stringr::str_detect(param$type, "choice")) {
      param$feature <- "Choice"
    }

    if (stringr::str_detect(param$type, "floating point")) {
      param$feature <- "numeric"
    }

    if (stringr::str_detect(param$type, "boolean")) {
      param$feature <- "logical"
    }

    if (stringr::str_detect(param$type, "long text")) {
      param$feature <- "character"
    }

    if (stringr::str_detect(param$type, "text")) {
      param$feature <- "character"
    }

    class(param) <- "parameter"
    param
  }

#' Updates a `parameter` object with file paths to the R data objects.
#'
#' @param param A `parameter` object.
#' @param temp_path A character specifying the tempdir to use for storage
#'   (optional).
#' @param raster_format name of raster format in `supported_raster_formats`
#' @param vector_format file extension for vector formats in
#'   `supported_vector_formats`
#'
#' @return A `parameter` object with an updated `file` attribute that refers to
#'   the on-disk file for saga_cmd to access.
#' @keywords internal
update_parameter_file <-
  function(param,
           temp_path = NULL,
           raster_format,
           vector_format) {
    if (!is.null(param$value)) {
      # update the `files` attribute with the file path to the object
      # in `parameter$value` attribute
      param$files <-
        save_object(
          param$value,
          temp_path = temp_path,
          raster_format = raster_format,
          vector_format = vector_format
        )
    }

    # collapse lists into semi-colon separated string
    if (length(param$files) > 1) {
      param$files <- paste(param$files, collapse = ";")
    }

    param
  }


#' Updates a `parameters` object with file paths to the R data objects.
#'
#' @param params A `parameters` object.
#' @param temp_path A character specifying the tempdir to use for storage
#'   (optional).
#' @param raster_format file extension for raster formats
#' @param vector_format file extension for vector formats
#'
#' @return A `parameters` object with updated `file` attributes that refers to
#'   the on-disk file for saga_cmd to access.
#' @keywords internal
update_parameters_file <-
  function(params,
           temp_path = NULL,
           raster_format,
           vector_format) {
    # update the `file` attribute of each `parameter` object
    params <-
      lapply(
        params,
        update_parameter_file,
        temp_path = temp_path,
        raster_format = raster_format,
        vector_format = vector_format
      )

    return(params)
  }


#' Update a `parameters` object using temporary files for any unspecified output
#' parameters
#'
#' @param params A `parameters` object.
#' @param temp_path A character with the tempdir.
#' @param raster_format A character specifying the raster format.
#' @param vector_format A character specifying the vector format.
#'
#' @return A `parameters` object.
#'
#' @keywords internal
update_parameters_tempfiles <- function(params, temp_path, raster_format,
                                        vector_format) {
  parameter_outputs <- params[sapply(params, function(param) !is.na(param$io))]

  parameter_outputs <-
    parameter_outputs[
      sapply(parameter_outputs, function(param) param$io == "Output")
    ]

  parameter_outputs <- names(parameter_outputs)

  grid_features <- c("Grid", "Raster")
  shape_features <- c("Shape")
  table_features <- "Table"
  cannot_handle_features <- c("Grid list", "Shapes list")

  for (n in parameter_outputs) {
    if (params[[n]]$io == "Output" & is.null(params[[n]]$files)) {

      # get tempfile with correct file extension
      if (params[[n]]$feature %in% grid_features) {
        params[[n]]$files <- tempfile(
          tmpdir = temp_path,
          fileext = raster_format
        )
      } else if (params[[n]]$feature %in% shape_features) {
        params[[n]]$files <- tempfile(
          tmpdir = temp_path,
          fileext = vector_format
        )
      } else if (params[[n]]$feature == table_features) {
        params[[n]]$files <- tempfile(tmpdir = temp_path, fileext = ".csv")
      } else {
        rlang::abort(
          paste(
            "Rsagacmd cannot determine the number of results for list-like outputs.",
            "For Grid/Shapes list outputs, please provide file path(s) to the tool's output arguments."
          )
        )
      }

      params[[n]]$value <- params[[n]]$files

      # add to tempfile list
      tfiles <- params[[n]]$files
      tfiles <- strsplit(tfiles, ";")
      pkg.env$sagaTmpFiles <- append(pkg.env$sagaTmpFiles, tfiles)
    }
  }

  params
}


#' Drops unused/empty parameters from a `parameters` object
#'
#' @param params A `parameters` object
#'
#' @return A `parameters` object with empty `parameter` objects removed
#'
#' @keywords internal
drop_parameters <- function(params) {
  params <- params[sapply(params, function(param) !is.null(param$value))]
  class(params) <- "parameters"
  params
}
