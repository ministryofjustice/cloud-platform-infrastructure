package cloud_platform.admission

# concatenated messages produced by the deny rule
denied_msg = concat(", ", deny)

denied = denied_msg != ""
