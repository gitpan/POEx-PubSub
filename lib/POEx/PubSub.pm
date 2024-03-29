package POEx::PubSub;
BEGIN {
  $POEx::PubSub::VERSION = '1.102740';
}

#ABSTRACT: A second generation publish/subscribe component for the POE framework


use MooseX::Declare;

class POEx::PubSub {
    use POEx::PubSub::Event;
    with 'POEx::Role::SessionInstantiation';
    use aliased 'POEx::Role::Event';
    use Carp('carp', 'confess');
    use POE::API::Peek;
    use POEx::PubSub::Types(':all');
    use MooseX::Types;
    use MooseX::Types::Moose(':all');
    use POEx::Types(':all');
    
    sub import {
        no strict 'refs';
        my $caller = caller();
        *{ $caller . '::PUBLISH_INPUT' } = \&PUBLISH_INPUT;
        *{ $caller . '::PUBLISH_OUPUT' } = \&PUBLISH_OUPUT;
    }
    
    
    has _api_peek =>
    (
        is          => 'ro',
        isa         => class_type('POE::API::Peek'),
        default     => sub { POE::API::Peek->new() },
        lazy        => 1,
    );


    has _events => 
    (
        traits      => ['Hash'],
        is          => 'rw', 
        isa         => HashRef[class_type('POEx::PubSub::Event')],
        clearer     => '_clear__events',
        default     => sub { {} },
        lazy        => 1,
        handles     => {
            all_events => 'values',
            add_event => 'set',
            remove_event => 'delete',
            get_event => 'get',
            has_events => 'count',
        }
    );


    method _default(ArrayRef $args) is Event {
        my $poe = $self->poe;
        my $state = $poe->state;
        my $warn = $self->options->{'debug'};

        if(my $event = $self->get_event($state)) {
            if($event->publishtype == +PUBLISH_OUTPUT) {
                my $sender = $poe->sender->ID;
                if(!$event->has_publisher || !$event->publisher == $sender) {
                    carp("Event [ $event ] is not owned by Sender: " . $sender) if $warn;
                    return;
                }

                if(!$event->has_subscribers) {
                    carp("Event[ $event ] currently has no subscribers") if $warn;
                    return;
                }

                foreach my $subscriber ($event->all_subscribers) {
                    my ($s_session, $s_event) = @{ $subscriber }{'session', 'event'};
                    if(!$self->_has_event(session => $s_session, event_name => $s_event)) {
                        carp("$s_session no longer has $s_event in their events") if $warn;
                        $self->remove_subscriber($s_session);
                    }
                    
                    $self->post($s_session, $s_event, @$args);
                }
                return;
            }
            else {
                $self->post(
                    $poe->kernel->ID_id_to_session($event->publisher), 
                    $event->input, 
                    @$args);
            }
        }
        else {
            carp("Event [ $state ] does not currently exist") if $warn;
            return;
        }
    }


    method destroy is Event {
        $self->_clear__events;
        my $kernel = $self->poe->kernel;
        $kernel->alias_remove($_) for $kernel->alias_list();
    }


    method listing(SessionRefIdAliasInstantiation :$session?, Str :$return_event?) is Event returns (ArrayRef) {
        if($return_event && $session) {
            $session ||= $self->poe->sender->ID;
            $session = is_SessionID($session) ? $session : to_SessionID($session) or confess("Unable to coerce $session to SessionID");
            
            if(!$self->_has_event(session => $session, event_name => $return_event)) {
                carp("$session must own the $return_event event") if $self->options->{'debug'}; 
                return;
            }
        }

        my $events = [$self->all_events];
    
        $self->poe->kernel->post($session, $return_event, $events) if $return_event;
        return $events;
    }


    method publish(SessionRefIdAliasInstantiation :$session?, Str :$event_name!, PublishType :$publish_type?, Str :$input_handler?) is Event {
        $session ||= $self->poe->sender->ID;
        $session = is_SessionID($session) ? $session : to_SessionID($session) or confess("Unable to coerce $session to SessionID");
        my $warn = $self->options->{'debug'};

        if(my $event = $self->get_event($event_name)) {
            if($event->has_publisher) {
                carp("Event [ $event_name ] already has a publisher") if $warn;
                return;
            }
            
            if(defined($publish_type) && $publish_type == +PUBLISH_INPUT) {
                if(!defined($input_handler)) {
                    carp('$input_handler argument is required for publishing an input event') if $warn;
                    return;
                }

                if(!$self->_has_event(session => $session, event_name => $input_handler)) {
                    carp("$session must own the $input_handler event") if $warn;
                    return;
                }

                if($event->has_subscribers) {
                    carp("Event [ $event_name ] already has subscribers and precludes publishing") if $warn;
                    return;
                }
            }

            $event->publisher($session);
        }
        else {
            my %args;

            if(defined($publish_type) && $publish_type == +PUBLISH_INPUT) {
                if(!defined($input_handler)) {
                    carp('$input_handler argument is required for publishing an input event') if $warn;
                    return;
                }

                if(!$self->_has_event(session => $session, event_name => $input_handler)) {
                    carp("$session must own the $input_handler event") if $warn;
                    return;
                }
                
                @args{'publishtype', 'input'} = ($publish_type, $input_handler);
            }

            my $event = 'POEx::PubSub::Event'->new
            (
                name => $event_name,
                publisher => $session,
                %args
            );

            $self->add_event($event_name, $event);
        }
    }

    method subscribe(SessionRefIdAliasInstantiation :$session?, Str :$event_name, Str :$event_handler) is Event {
        $session ||= $self->poe->sender->ID;
        $session = is_SessionID($session) ? $session : to_SessionID($session) or confess("Unable to coerce $session to SessionID");
        my $warn = $self->options->{'debug'};

        if(my $event = $self->get_event($event_name)) {
            if($event->publishtype == +PUBLISH_INPUT) {
                carp("Event[ $event_name ] is not an output event") if $warn;
                return;
            }

            if(!$self->_has_event(session => $session, event_name => $event_handler)) {
                carp("$session must own the $event_handler event") if $warn;
                return;
            }

            $event->add_subscriber($session => {session => $session, event => $event_handler});
        }
        else {
            my $event = 'POEx::PubSub::Event'->new(name => $event_name);
            $event->add_subscriber($session => {session => $session, event => $event_handler});
            $self->add_event($event_name, $event);
        }
    }


    method rescind(SessionRefIdAliasInstantiation :$session?, Str :$event_name) is Event {
        $session ||= $self->poe->sender->ID;
        $session = is_SessionID($session) ? $session : to_SessionID($session) or confess("Unable to coerce $session to SessionID");
        my $warn = $self->options->{'debug'};

        if(my $event = $self->get_event($event_name)) {
            if($event->publisher != $session) {
                carp("Event[ $event_name ] is not owned by $session") if $warn;
            }

            if($event->has_subscribers) {
                carp("Event[ $event_name ] currently has subscribers, but removing anyway") if $warn;
            }
            
            $self->remove_event($event_name);
        }
        else {
            carp("Event[ $event_name ] does not exist") if $warn;
        }
    }


    method cancel(SessionRefIdAliasInstantiation :$session?, Str :$event_name) is Event {
        $session ||= $self->poe->sender->ID;
        $session = is_SessionID($session) ? $session : to_SessionID($session) or confess("Unable to coerce $session to SessionID");
        my $warn = $self->options->{'debug'};
        
        if(my $event = $self->get_event($event_name)) {
            if(my $subscriber = $event->get_subscriber($session)) {
                $event->remove_subscriber($session);
            }
            else {
                carp("$session must be subscribed to the $event_name event") if $warn;
            }
        }
        else {
            carp("Event[ $event_name ] does not exist") if $warn;
        }
    }


    method _has_event(SessionID :$session, Str :$event_name) {
        return 0 if not defined($event_name);

        my $session_ref = $self->poe->kernel->ID_id_to_session($session);

        if($session_ref->isa('Moose::Object') && $session_ref->does('POEx::Role::SessionInstantiation')) {
            return defined($session_ref->meta->get_method($event_name));
        }
        else {
            return scalar ( grep { /$event_name/ } $self->_api_peek->session_event_list($session_ref));
        }
    }
}

1;


=pod

=head1 NAME

POEx::PubSub - A second generation publish/subscribe component for the POE framework

=head1 VERSION

version 1.102740

=head1 SYNOPSIS

    #imports PUBLISH_INPUT and PUBLISH_OUTPUT
    use POEx::PubSub;
    
    # Instantiate the publish/subscriber with the alias "pub"
    POEx::PubSub->new(alias => 'pub');

    # Publish an event called "FOO". +PUBLISH_OUTPUT is actually optional.
    $_[KERNEL]->post
    (
        'pub', 
        'publish', 
        event_name => 'FOO', 
        publish_type => +PUBLISH_OUTPUT
    );

    # Elsewhere, subscribe to that event, giving it an event to call
    # when the published event is fired.
    $_[KERNEL]->post
    (
        'pub', 
        'subscribe', 
        event_name => 'FOO', 
        event_handler => 'FireThisEvent'
    );

    # Fire off the published event
    $_[KERNEL]->post('pub', 'FOO');

    # Publish an 'input' event
    $_[KERNEL]->post
    (
        'pub', 
        'publish', 
        event_name => 'BAR', 
        publish_type => +PUBLISH_INPUT, 
        input_handler =>'MyInputEvent'
    );

    # Publish an event for another session
    $_[KERNEL]->post
    (
        'pub',
        'publish',
        session => 'other_session',
        event_name => 'SomeEvent',
    );

    # Subscribe to an event for another session
    $_[KEREL]->post
    (
        'pub',
        'publish,
        session => 'other_session',
        event_name => 'SomeEvent',
        event_handler => 'other_sessions_handler',
    );

    # Tear down the whole thing
    $_[KERNEL]->post('pub', 'destroy');

=head1 DESCRIPTION

POEx::PubSub provides a publish/subscribe mechanism for the POE
framework allowing sessions to publish events and to also subscribe to those 
events. Firing a published event posts an event to each subscriber of that 
event. Publication and subscription can also be managed from an external
session, but defaults to using the SENDER where possible.

=head1 PRIVATE_ATTRIBUTES

=head2 _api_peek

    is: ro, isa: class_type('POE::API::Peek')

This is a private attribute for accessing POE::API::Peek.

=head2 _events 

This is a private attribute for accessing the PubSub::Events stored in this 
instance of PubSub keyed by the event name. If events need to be accessed please use the provided methods:
 {
        all_events => 'values',
        add_event => 'set',
        remove_event => 'delete',
        get_event => 'get',
        has_events => 'count',
    }

=head1 PUBLIC_METHODS

=head2 destroy

    is Event

This event will simply destroy any of its current events and remove any and all
aliases this session may have picked up. This should free up the session for
garbage collection.

=head2 listing

    (SessionRefIdAliasInstantiation :$session?, Str :$return_event?) is Event returns (ArrayRef)

To receive a listing of all the of the events inside of PubSub, you can either
call this event and have it returned immediately, or return_event must be 
provided and implemented in either the provided session or SENDER and the only
argument to the return_event will be the events.

=head2 publish

    (SessionRefIdAliasInstantiation :$session?, Str :$event_name!, PublishType :$publish_type?, Str :$input_handler?) is Event

This is the event to use to publish events. The published event may not already
be previously published. The event may be completely arbitrary and does not 
require the publisher to implement that event. Think of it as a name for a 
mailing list.

You can also publish an 'input' or inverse event. This allows for arbitrary
sessions to post to your event. In this case, you must supply the optional
published event type and the event to be called when the published event fires. 

There are two types: PUBLISH_INPUT and PUBLISH_OUTPUT. PUBLISH_OUPUT is implied
when no argument is supplied.

Also, you can publish an event from an arbitrary session as long as you provide
a session alias.

=head2 subscribe

    (SessionRefIdAliasInstantiation :$session?, Str :$event_name, Str :$event_handler) is Event

This event is used to subscribe to a published event. The event does not need
to exist at the time of subscription to avoid chicken and egg scenarios. The
event_handler must be implemented in either the provided session or in the 
SENDER. 

=head2 rescind

    (SessionRefIdAliasInstantiation :$session?, Str :$event_name) is Event

Use this event to stop publication of an event. The event must be published by
either the provided session or SENDER

=head2 cancel

    (SessionRefIdAliasInstantiation :$session?, Str :$event_name) is Event

Cancel subscriptions to events with this event. The event must contain the
provided session or SENDER as a subscriber

=head1 PRIVATE_METHODS

=head2 _default

    (ArrayRef $args) is Event

After an event is published, the publisher may arbitrarily fire that event to
this component and the subscribers will be notified by calling their respective
return events with whatever arguments are passed by the publisher. The event 
must be published, owned by the publisher, and have subscribers for the event
to be propagated. If any of the subscribers no longer has a valid return event
their subscriptions will be cancelled and a warning will be carp'd.

This overrides POEx::Role::SessionInstantiation::_default().

=head2 _has_event(SessionID :$session, Str :$event_name)

This is a private method used by PubSub to confirm the session has the stated 
event. If it is class that composed SessionInstantiation, it checks via MOP,
otherwise it uses POE::API::Peek to accomplis the deed.

=head1 AUTHOR

Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas Perez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
