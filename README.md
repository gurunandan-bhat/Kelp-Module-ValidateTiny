# NAME

Kelp::Module::ValidateTiny - Validate parameters in a Kelp Route Handler

# VERSION

Version 0.01

# SYNOPSIS

    use Kelp::Module::ValidateTiny;
    # inside your Kelp config file 
    {
        modules => [ qw{SomeModule Validate::Tiny} ],
        modules_init => {
            ...
            ,
            # :all will import everything
            # no need to list MyApp here
            'Validate::Tiny' => {
                subs => [ qw{is_required is_required_id} ],
                into => [ qw{MyApp::OtherRouteClass} ], 
            }
        }
    }
    ...
    #inside a Kelp route

    my $vt_rules = {
        fields => [...],
        filters => [...],
        checks => [...],
    };
    

    my $result = $self->validate($vt_rules)
    # $result is a Validate::Tiny object

    # process $result
    ...
    

    # render the template form.tt if validation fails
    # $errors and valid values are automatically passed, 
    # to the template, but you can optionally pass some 
    # more data to that template

    $self->validate($rules, 
        on_error => 'form.tt',
        data => {
            message => 'You could try something else'
        },
    );

# DESCRIPTION

Kelp::Module::ValidateTiny adds Validate::Tiny's validator to your Kelp application.

# METHODS

## validate

This is the only method decorating $self. You can call it in three ways:

First you can pass it just a valid Validate::Tiny $rules hash reference. It 
will return a Validate::Tiny object and you can call all the usual V::T
methods on it.

    my $result = $self->validate($rules);
    # $result is now a Validate::Tiny object
    

Second you can pass it a name ('on\_fail') and value (a template filename) pair. 
If your data passed the validation, the return value is the usual V::T object. 
However, if validation fails, the function does not return but renders the 
template file that you passed it with the same parameters (get, post, named) 
that it received plus an additional key 'error' that points to a hashref whose 
key value pairs are the field names and error messages.

    my $result = $self->validate(
        $rules,
        on_error => 'form'
    );
    

    # You reached here because all validations passed.
    # You can now call $result->data to get the filtered
    # validated data 

This can be useful with a construct like `[% error.name | name %]` 
in your template.

Third, you can pass some additional values that will be passed "as is"" to the 
on\_fail template  
    

    $self->validate($rules, 
        on_error => 'form.tt',
        data => {
            helpful_message => 'You could try something else next time!'
        },
    );

# AUTHOR

Gurunandan R. Bhat <gbhat@pobox.com>

# COPYRIGHT

Copyright 2013- Gurunandan R. Bhat

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
