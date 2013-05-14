# Common settings
{
    modules      => [qw/Template ValidateTiny/],
    modules_init => {

        # Enable UTF-8 in Template
        Template => {
            ENCODING => 'utf8'
        }
    }
};
