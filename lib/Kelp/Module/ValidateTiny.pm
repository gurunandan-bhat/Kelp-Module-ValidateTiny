package Kelp::Module::ValidateTiny;

use Kelp::Base 'Kelp::Module';

use Validate::Tiny;

use Class::Load;
use Sub::Install;

our $VERSION = '0.02';

# These are Validate::Tiny functions that we 
# forward into the application namespace
 
my @forward_ok = qw{
    filter
    is_required
    is_required_if
    is_equal
    is_long_between
    is_long_at_least
    is_long_at_most
    is_a
    is_like
    is_in
};

sub build {
    
    my ($self, %args) = @_;
    
    my @import;
    # Imported from Validate::Tiny?
    if (%args && 
        exists $args{subs}) {

            @import = @{$args{subs}};
        }
        
    @import = @forward_ok if (@import && $import[0] eq ':all');

    # Namespaces to import into (default is our App)
    # If our App name is Kelp, we are probably running 
    # from a standalone script and our classname is main
    
    my $class = ref $self->app;
    $class = 'main' if ($class eq 'Kelp');
    my @into = ($class);

    if (%args &&
        exists $args{into}) {
            
            push @into, @{$args{into}};
        }
    
    # Import!
    foreach (@into) {
        
        my $class = $_;

        Class::Load::load_class($class) 
          unless Class::Load::is_class_loaded($class);
          
        foreach (@import) {
            
            Sub::Install::install_sub({
                code => Validate::Tiny->can($_),
                from => 'Validate::Tiny',
                into => $class,
            });
        }
    }

    # Register a single method - self->validate
    $self->register(
        validate => \&_validate
    );
}

sub _validate {

    my $self = shift;
    my $rules = shift;
    my %args = @_;
    
    # Combine all params
    # TODO: check if mixed can be avoided 
    # on the Hash::Multivalue "parameters"

    my $input = {
        %{$self->req->parameters->mixed}, 
        %{$self->req->named}
    };
    
    my $result = Validate::Tiny->new($input, $rules);
    
    return $result if (
       $result->success || (!(%args && exists $args{on_error}))
    );
    
    # There are errors and a template is passed

    my $data = $result->data;
    $data->{error} = $result->error;

    if (exists $args{data}) {
        $data = {
            %$data,
            %{$args{data}},
        };
    }

    $self->res->template($args{on_error}, $data);
}

1;
__END__

=encoding utf-8

=head1 NAME

Kelp::Module::ValidateTiny - Validate parameters in a Kelp Route Handler

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Kelp::Module::ValidateTiny adds Validate::Tiny's validator to your Kelp application.

=head1 METHODS

=head2 validate

This is the only method decorating $self. You can call it in three ways:

First you can pass it just a valid Validate::Tiny $rules hash reference. It 
will return a Validate::Tiny object and you can call all the usual V::T
methods on it.

    my $result = $self->validate($rules);
    # $result is now a Validate::Tiny object
    
Second you can pass it a name ('on_fail') and value (a template filename) pair. 
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

This can be useful with a construct like C<[% error.name | name %]> 
in your template.

Third, you can pass some additional values that will be passed "as is"" to the 
on_fail template  
    
    $self->validate($rules, 
        on_error => 'form.tt',
        data => {
            helpful_message => 'You could try something else next time!'
        },
    );

=head1 AUTHOR

Gurunandan R. Bhat E<lt>gbhat@pobox.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Gurunandan R. Bhat

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
