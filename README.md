# Description (forthcoming)

Vision: To host an electronic library of Pacific salmon stressor-response functions as a “one-stop-shop” for life cycle modelers that is searchable, user-friendly, and open-source

This e-Library will:

- store stressor-response functions for different species, life stages, and environmental stressors
- make it easier for modelers and model users to find the most appropriate relationships for the target species and region
- increase transparency because users can examine the sources informing relationships used in models
- produce economies of scale, efficiencies, and a reduction in redundant work across different modeling teams

# User Guide

## Stressor Response Metadata and Data Documentation

This e-library is designed to support life cycle modelers, resource managers, and scientists by making stressor-response (SR) functions discoverable, transparent, and reusable. Each SR function describes the quantitative relationship between a stressor (e.g., temperature, flow, harvest, contaminants) and a biological response (e.g., survival, growth, migration timing, capacity, productivity).

The library contains two main components:

1. **Metadata** - standardized fields describing the SR function, its source, and context
1. **Extracted data** - numerical data extracted from the article (or supplemental datasets) that has been formatted for reuse and analysis

## Metadata Fields

Each entry has an identifier and descriptive metadata fields.

| Field                                    | Description                                                                                                                                                                                                                                                                           |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Main ID                                  | Identifier for the SR function. Links metadata to the associated dataset                                                                                                                                                                                                              |
| Citation                                 | Full citation of the primary research article                                                                                                                                                                                                                                         |
| Stressor Title                           | Title of the SR function. Format: _Author et al. Year: Function description. Example: Honea et al. 2016: Chinook egg-to-fry survival vs incubation temperature_                                                                                                                       |
| Species Common                           | Common species name (e.g., Chinook salmon, Sockeye salmon)                                                                                                                                                                                                                            |
| Species Latin Genus                      | Genus name (e.g., _Oncorhynchus_)                                                                                                                                                                                                                                                     |
| Species Latin                            | Species name (e.g., _kisutch_, _tshawytscha_)                                                                                                                                                                                                                                         |
| Life Stage                               | Life stage of fish (e.g., fry, smolt, adult, egg)                                                                                                                                                                                                                                     |
| Activity                                 | Fish activity examined (e.g., incubation, spawning, rearing, migration)                                                                                                                                                                                                               |
| Season                                   | Season relevant to the study (e.g., spring, summer, fall, winter)                                                                                                                                                                                                                     |
| Response                                 | Biological response measured (e.g., egg-to-fry survival, smolt abundance, growth)                                                                                                                                                                                                     |
| Stressor Name                            | General stressor on the x-axis (e.g., temperature, angling effort, alkalinity)                                                                                                                                                                                                        |
| Specific Stressor Metric                 | Specific metric of the stressor (e.g., incubation temperature, incidental angling mortality)                                                                                                                                                                                          |
| Stressor Units                           | Units of measurements (e.g., mg/L, %, ℃)                                                                                                                                                                                                                                              |
| Stressor Scale                           | Mathematical scale of the stressor variable: linear or logarithmic. Example: incubation temperature → linear scale                                                                                                                                                                    |
| Function Type                            | Type of function: continuous or step                                                                                                                                                                                                                                                  |
| Function Derivation                      | Short summary of how the SR function was derived (e.g., lab trials, field data)                                                                                                                                                                                                       |
| Detailed Function Derivation             | Provides a transparent, comprehensive description of how the SR function was derived, including data and methods. This section should allow a reader to reconstruct the function’s logic and assumptions.                                                                             |
| Model Validation                         | Describes whether and how the SR function has been tested against independent data or observations. Validation indicates the degree of confidence in applying the function beyond its original dataset. (e.g., unvalidated, partially validated, validated with independent dataset). |
| Transferability of Function              | Evaluates whether the SR function can be applied beyond the specific context in which it was developed. This helps users understand the limits of generalization.                                                                                                                     |
| POE (Pathway of Effects) (if applicable) | Mechanistic pathway linking the stressor to the biological response (e.g., high temperature → low dissolved oxygen → reduced egg survival), if applicable                                                                                                                             |
| Research Article Type                    | Type of article (e.g., meta-analysis, field experiment, lab experiment, mechanistic model)                                                                                                                                                                                            |
| Abstract                                 | Abstract of the article, or NA if not available                                                                                                                                                                                                                                       |
| References                               | Citations for additional sources if the SR function draws on multiple papers                                                                                                                                                                                                          |
| Stressor Data Source                     | Source of stressor data if not directly from the primary article                                                                                                                                                                                                                      |
| Location (Country)                       | Country where the study was conducted                                                                                                                                                                                                                                                 |
| Location (State)                         | State or province                                                                                                                                                                                                                                                                     |
| Location (Watershed/Laboratory)          | Watershed or Laboratory or Hatchery                                                                                                                                                                                                                                                   |
| Location (River/Creek)                   | River or Creek, if applicable                                                                                                                                                                                                                                                         |

## Extracted Data

When you download an SR function as a CSV, you receive:

1. Metadata (all fields above), and
1. Extracted data table - numerical data pulled from figures, tables, or supplementary files.

The extracted CSV data have two to four standardized columns:

| Column          | Description                                                                      |
| --------------- | -------------------------------------------------------------------------------- |
| Stressor (X)    | Numeric value of the stressor (x-axis)                                           |
| Response (Y)    | Numeric value of the biological response (y-axis)                                |
| Treatment Label | Treatment or condition label (e.g., temperature, flow, flow x temperature, etc.) |
| Treatment Value | Numeric representation of the treatment, if applicable                           |

_Note: All entries in the extracted dataset include a Stressor (x) and Response (y) value, while Treatment Label and Treatment Value are only present when applicable. Early entries contributed by Canadian partners (CEMPRA, Joe Model) reported the biological response as “Mean System Capacity”, which scales response values from 0% to 100%. Since NOAA assumed responsibility for the library and expanded its scope, response values have been retained in the original units and formats presented in each paper, rather than standardized. Extracted data may come from digitized figures, reported tables, or supplemental datasets. Small uncertainties may exist in digitized data, which are noted where possible._

## Attribution

If you use data from this library, please cite the original research article(s).

# Collaborators

<table>
  <tr>
    <td>
      <a href="https://github.com/aimeefullerton">
        <figure align="center">
          <img src="https://github.com/aimeefullerton.png" width=50 height=50/>
          <br/>
          <figcaption width=50>Aimee Fullerton</figcaption>
        </figure>
      </a>
    </td>
    <td>
      <a href="https://github.com/Morganbond">
        <figure align='center'>
          <img src="https://github.com/Morganbond.png" width=50 height=50/>
          <br/>
          <figcaption>Morgan Bond</figcaption>
        </figure>
      </a>
    </td>
    <td>
      <a href="https://github.com/Paxtonc07">
        <figure align='center'>
          <img src="https://github.com/Paxtonc07.png" width=50 height=50/>
          <br/>
          <figcaption>Paxton Calhoun</figcaption>
        </figure>
      </a>
    </td>
    <td>
      <a href="https://github.com/DrAcula27">
        <figure align='center'>
          <img src="https://github.com/DrAcula27.png" width=50 height=50/>
          <br/>
          <figcaption>
            Danielle Andrews
            <br />
            (external)
          </figcaption>
        </figure>
      </a>
    </td>
  </tr>
</table>

# Disclaimer

This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project content is provided on an "as is" basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government.
