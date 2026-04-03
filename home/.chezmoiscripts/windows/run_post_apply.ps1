# Install mise packages
if (Get-Command "mise" -ErrorAction SilentlyContinue) {
    mise install
}