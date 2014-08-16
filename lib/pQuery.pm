use strict; use warnings;
package pQuery;
our $VERSION = '0.16';

use pQuery::DOM;
use Carp;

use HTML::TreeBuilder 4.2 ();

use base 'Exporter';

our $document;
*pQuery = \$document;

our @EXPORT = qw(pQuery $pQuery PQUERY);

my $my = {};
my $lwp_user_agent;
my $quickExpr = qr/^([^<]*<(.|\s)+>[^>]*)$|^#(\w+)$/;
my $isSimple = qr/^.[^:#\[\.]*$/;
my $dom_element_class = 'pQuery::DOM';

sub pQuery {
    return 'pQuery'->new(@_);
}

sub PQUERY {
    return 'PQUERY'->new(@_);
}

#------------------------------------------------------------------------------#
# New ideas / Playing around stuffs
#------------------------------------------------------------------------------#
sub url {
    my $this = shift;
    return $my->{$this}{url}
        if $my->{$this}{url};
    while ($this = $my->{$this}{prevObject}) {
        return $my->{$this}{url}
            if $my->{$this}{url};
    }
    return;
}

#------------------------------------------------------------------------------#
# Truly ported from jQuery stuff
#------------------------------------------------------------------------------#
sub new {
    my $class = shift;
    my $this = bless [], $class;
    $my->{$this} = {};
    return $this->_init(@_);
}

sub _init {
    my ($this, $selector, $context) = @_;

    $selector ||= $document or return $this;

    if (ref($selector) eq $dom_element_class) {
        @$this = $selector;
        return $this;
    }
    elsif (not ref($selector)) {
        my $match = ($selector =~ m/$quickExpr/o);

        if ($match and ($1 or not $context)) {
            if ($1) {
                my $html = $this->_clean($1);
                $selector = [pQuery::DOM->fromHTML($html)];
#                 $selector = $this->_clean([$1], $context);
            }
            else {
                my $elem = $document->getElementById($3);
                if ($elem) {
                    @$this = $elem;
                    return $this;
                }
                else {
                    $selector = [];
                }
            }
        }
        else {
            if ($selector =~ /^\s*(https?|file):/) {
                $my->{$this}{url} = $selector;
                return $document = $this->_new_from_url($selector);
            }
            elsif ($selector =~ /^\S+\.html?$/) {
                $my->{$this}{file} = $selector;
                open FILE, $selector
                    or croak "Can't open file '$selector' for input:\n$!";
                my $html = do {local $/; <FILE>};
                close FILE;
                $html = $this->_clean($html);
                $selector = [$document = pQuery::DOM->fromHTML($html)];
            }
            else {
                $context ||= $document;
                return pQuery($context)->find($selector);
            }
        }
    }
    @$this = (ref($selector) eq 'ARRAY' or ref($selector) eq 'pQuery')
        ? @$selector
        : $selector;
    return $this;
}

sub _clean {
    my ($this, $html) = @_;
    $html =~ s/^\s*<\?xml\s.*?>\s*//s;
    $html =~ s/^\s*<!DOCTYPE\s.*?>\s*//s;
    return $html;
}

sub pquery { return $VERSION }

sub size { return $#{$_[0]} + 1 }

sub get {
    my $this = shift;

    # Get could be for Ajax URL or Object Member
    return $this->_web_get(@_)
        if @_ and $_[0] !~ /^\d+$/;

    return @_
        ? $this->[$_[0]]
        : wantarray ? (@$this) : $this->[0];
}

sub pushStack {
    my ($this, $elems) = @_;
    my $ret = pQuery($elems);
    $ret->_prevObject($this);
    return $ret;
}

sub _prevObject {
    my $this = shift;
    return @_
        ? ($my->{$this}{prevObject} = $_[0])
        : $my->{$this}{prevObject};
}

# Not needed in Perl
# sub _setArray {}

sub each {
    my ($this, $sub) = @_;
    my $i = 0;
    &$sub($i++) for @$this;
    return $this;
}

sub attr { # (elem, name, value)

    my ($elem, $name, $value) = @_;

        my $node = $elem->[0];

        # don't set attributes on text and comment nodes
        return undef if (!$node || $node->nodeType eq 3 || $node->nodeType eq 8);

        if ( defined $value ) {
            # convert the value to a string
            $node->setAttribute( $name, $value );
        }

        return $node->getAttribute( $name );

}

sub css { # (key, value)
    # TODO - Get/set a css attribute
}

# TODO/XXX Made up. Not ported yet.
sub text {
    # TODO - Get/set text value
    my $this = shift;
    my @text;

    $this->each(sub {
        my $text = '';
        _to_text($_, \$text);
        $text =~ s/\s+/ /g;
        $text =~ s/^\s+|\s+$//g;
        push @text, $text;
    });

    return wantarray ? @text : join(' ', grep /\S/, @text);
}

sub wrapAll { # (html)
    # TODO - Wrap element with HTML
}

sub wrapInner { # (html)
    # TODO - Wrap sub elements with HTML
}

sub wrap { # (html)
    # TODO - Wrap current objects with HTML
}

sub append { # (@_)
    # TODO - Append arguments to current objects
}

sub prepend { # (@_)
    # TODO - Prepend arguments to current objects
}

sub before { # (@_)
    # TODO - Insert arguments before current objects
}

sub after { # (@_)
    # TODO - Insert arguments after current objects
}

sub end {
    my $this = shift;
    return $this->_prevObject || pQuery([]);
}

sub find {
    my ($this, $selector) = @_;
    my $elems = [];

    for (my $i = 0; $i < @$this; $i++) {
        push @$elems, @{$this->_find($selector, $this->[$i])};
    }

    return $this->pushStack(
        $selector =~ /[^+>] [^+>]/
        ? $this->_unique($elems)
        : $elems
    )
}

sub clone { # (events)
    # TODO - Not sure if we need this one.
}

sub filter { # (selector)
    # TODO - A kind of grep
}

sub add { # (selector)
    # TODO - Some kind of merge
}

sub is { # (selector)
    # TODO - One element matches the selector
}

sub hasClass {
    my ($this, $selector) = @_;
    $this.is(".$selector");
}

sub val { # (value)
    # TODO Get/set
}

# XXX - Not really ported yet.
sub html {
    my $this = shift;
    return unless @$this;
    if (@_) {
        for (@$this) {
            next unless ref($_);
            $_->innerHTML(@_);
        }
        return $this;
    }
    return $this->[0]->innerHTML(@_);
}

# Not a jQuery function.
sub toHtml {
    my $this = shift;
    return unless @$this;
    return $this->[0]->toHTML;
}

# TODO - Not tested
sub replaceWith { # (value)
    my ($this, $value) = @_;
    return $this->after($value)->remove;
}

# TODO - Not tested
sub eq {
    my ($this, $i) = @_;
    return $this->pushStack($this->[$i]);
}

sub slice { #(i, j)
    # TODO - Behave like JS slice()
}

sub map {
    my ($this, $callback) = @_;
    return $this->pushStack(__map($this, sub {
        my ($elem, $i) = @_;
        return $callback->($elem, $i, $elem);
    }));
}

# TODO - Not tested
sub andSelf {
    my $this = shift;
    return $this.add($this->prevObject);
}

sub data { # (key, value)
    # TODO - Not sure
}

sub removeData { # (key)
    # TODO - Not Sure
}

sub domManip {
    my ($this, $args, $table, $reverse, $callback) = @_;
    my $elems;
    return $this->each(sub {
        if (not defined $elems) {
            $elems = $args;
            @$elems = reverse @$elems
              if $reverse;
        }
        pQuery::each($elems, sub {
            $callback->($this, $_);
        });
    });
}

#------------------------------------------------------------------------------#
# "Class" methods
#------------------------------------------------------------------------------#
# sub noConflict {}
# sub isFunction {}
# sub isXMLdoc {}
# sub globalEval {}

sub _nodeName {
    my ($this, $elem, $name) = @_;
    return $elem->nodeName &&
        uc($elem->nodeName) eq uc($name);
}


# sub cache {}
# sub data {}
# sub removeData {}
# sub each {}
# sub prop {}
# sub className {}
# sub swap {}
# sub css {}
# sub curCSS {}
# sub clean {}
# sub attr {}

sub _trim {
    (my $string = $_[1]) =~ s/^\s+|\s+$//g;
    return $string;
}

# sub makeArray {}
# sub inArray {}

sub _merge {
    push @{$_[1]}, @{$_[2]};
    return $_[1];
}

sub _unique {
    my $seen = {};
    return [ grep {not $seen->{$_}++} @{$_[1]} ];
}

sub _grep {
    my ($this, $elems, $callback, $inv) = @_;
    my $ret = [];

    for (my ($i, $length) = (0, scalar(@$elems)); $i < $length; $i++) {
        push @$ret, $elems->[$i]
            if (not $inv and &$callback($elems->[$i], $i)) or
               ($inv and not &$callback($elems->[$i], $i));
    }

    return $ret;
}

# sub map {}

#------------------------------------------------------------------------------#
# Selector functions
#------------------------------------------------------------------------------#
my $chars = qr/(?:[\w\x{128}-\x{FFFF}*_-]|\\.)/;
my $quickChild = qr/^>\s*($chars+)/;
my $quickId = qr/^($chars+)(#)($chars+)/;
my $quickClass = qr/^(([#.]?)($chars*))/;

my $expr = {
    # XXX Can't figure out how to create tests for these yet :(
    ""  => sub {
        die 'pQuery selector error #1001. Please notify ingy@cpan.org';
    },
    "#" => sub {
        die 'pQuery selector error #1002. Please notify ingy@cpan.org';
    },
    ":" => {
        # Position Checks
        lt => sub { return $_[1] < $_[2][3] },
        gt => sub { return $_[1] > $_[2][3] },
        nth => sub { return $_[2][3] == $_[1] },
        eq => sub { return $_[2][3] == $_[1] },
        first => sub { return $_[1] == 0 },
        last => sub { return $_[1] == $#{$_[3]} },
        even => sub { return $_[1] % 2 == 0 },
        odd => sub { return $_[1] % 2 },

        # Child Checks
        "first-child" => sub {
            return $_[0]->parentNode->getElementsByTagName("*")->[0] == $_[0];
        },
        "last-child" => sub {
            return pQuery->_nth(
                $_[0]->parentNode->lastChildRef,
                1,
                "previousSiblingRef"
            ) == $_[0];
        },
        "only-child" => sub {
            return ! pQuery->_nth(
                $_[0]->parentNode->lastChildRef,
                2,
                "previousSiblingRef"
            );
        },

        # Parent Checks
        parent => sub { return $_[0]->firstChild ? 1 : 0 },
        empty  => sub { return $_[0]->firstChild ? 0 : 1 },

        # Text Check
        contains => sub { return index(pQuery($_[0])->text, $_[2][3]) >= 0 },

# XXX Finish porting these if it makes sense...
#             // Visibility
#             visible: function(a){return "hidden"!=a.type&&jQuery.css(a,"display")!="none"&&jQuery.css(a,"visibility")!="hidden";},
#             hidden: function(a){return "hidden"==a.type||jQuery.css(a,"display")=="none"||jQuery.css(a,"visibility")=="hidden";},
#
#             // Form attributes
#             enabled: function(a){return !a.disabled;},
#             disabled: function(a){return a.disabled;},
#             checked: function(a){return a.checked;},
#             selected: function(a){return a.selected||jQuery.attr(a,"selected");},
#
#             // Form elements
#             text: function(a){return "text"==a.type;},
#             radio: function(a){return "radio"==a.type;},
#             checkbox: function(a){return "checkbox"==a.type;},
#             file: function(a){return "file"==a.type;},
#             password: function(a){return "password"==a.type;},
#             submit: function(a){return "submit"==a.type;},
#             image: function(a){return "image"==a.type;},
#             reset: function(a){return "reset"==a.type;},
#             button: function(a){return "button"==a.type||jQuery.nodeName(a,"button");},
#             input: function(a){return /input|select|textarea|button/i.test(a.nodeName);},


        # :has()
# XXX - The first form should work. Indicates that context is messed up.
#         has => sub { return pQuery->find($_[2][3], $_[0])->length ? 1 : 0 },
        has => sub { return pQuery($_[0])->find($_[2][3])->length ? 1 : 0 },

        # :header
        header => sub { return $_[0]->nodeName =~ /^h[1-6]$/i },
    },
};

# The regular expressions that power the parsing engine
my $parse = [
    # Match: [@value='test'], [@foo]
    qr/^(\[)\s*\@?([\w-]+)\s*((?:[\!\*\$\^\~\|\=]?\=)?)\s*([\'\"]?)(.*?)(?:\4)\s*\]/,

    # Match: :contains('foo')
    qr/^(:)([\w-]+)\(\"?\'?(.*?(\(.*?\))?[^(]*?)\"?\'?\)/,

    # Match: :even, :last-chlid, #id, .class
    qr/^([:.#]*)($chars+)/,
];

sub _multiFilter {
    # XXX - Port me.
}

sub _find {
    my ($this, $t, $context) = @_;

    return [ $t ]
        if ref($t);

    return []
        unless ref($context) and
        $context->can('nodeType') and
        $context->nodeType == 1;

    $context ||= $document or return [];

    my ($ret, $done, $last, $nodeName) = ([$context], [], '', '');

    while ($t and $last ne $t) {
        my $r = [];
        $last = $t;

        $t = $this->_trim($t);

        my $foundToken = 0;

        if ($t =~ s/$quickChild//o) {
            $nodeName = uc($1);
            for (my $i = 0; $ret->[$i]; $i++) {
                for (my $c = $ret->[$i]->firstChildRef; $c; $c = $c->nextSiblingRef) {
                    if ($c->nodeType == 1 and
                        (
                            $nodeName eq "*" or
                            uc($c->nodeName) eq $nodeName
                        )
                    ) { push @$r, $c }
                }
            }
            $ret = $r;
            $t = $this->_trim($t);
            $foundToken = 1;
        }
        else {
            if ($t =~ s/^([>+~])\s*(\w*)//) {
                $r = [];

                my $merge = {};
                $nodeName = uc($2);
                my $m = $1;

                for (my ($j, $rl) = (0, scalar(@$ret)); $j < $rl; $j++) {
                    my $n = ($m eq "~" or $m eq "+")
                        ? $ret->[$j]->nextSiblingRef
                        : $ret->[$j]->firstChildRef;
                    for (; $n; $n = $n->nextSiblingRef) {
                        if ($n->nodeType == 1) {
                            my $id = $n;
                            last if ($m eq "~" and $merge->{$id});
                            if (not $nodeName or
                                uc($n->nodeName) eq $nodeName
                            ) {
                                $merge->{$id} = 1 if $m eq "~";
                                push @$r, $n;
                            }
                            last if $m eq "+";
                        }
                    }
                }
                $ret = $r;

                $t = $this->_trim($t);
                $foundToken = 1;
            }
        }

        my $m;
        if ($t and not $foundToken) {
            if ($t =~ s/^,//) {
                shift @$ret if $context == $ret->[0];

                $done = $this._merge($done, $ret);

                $r = $ret = [$context];

                $t = " $t";
            }
            else {
                if ($t =~ s/$quickId//o) {
                    $m = [0, $2, $3, $1];
                }
                else {
                    if ($t =~ s/$quickClass//o) {
                        $m = [$1, $2, $3];
                    }
                }
                $m->[2] =~s/\\//g;

                my $elem = $ret->[-1];

                my $oid;
                if ($m->[1] eq "#" and
                    $elem and
                    $elem->can('getElementById')
                ) {
                    $oid = $elem->getElementById($m->[2]);
                    $ret = $r = (
                        $oid &&
                        (not $m->[3] or $this->_nodeName($oid, $m->[3]))
                    ) ? [$oid] : [];
                }
                else {
                    for (my $i = 0; $ret->[$i]; $i++) {
                        my $tag = ($m->[1] eq "#" and $m->[3])
                            ? $m->[3]
                            : ($m->[1] ne "" or $m->[0] eq "")
                                ? "*"
                                : $m->[2];
                        $r = $this->_merge(
                            $r,
                            $ret->[$i]->getElementsByTagName($tag)
                        );
                    }

                    $r = $this->_classFilter($r, $m->[2])
                        if ($m->[1] eq ".");

                    if ($m->[1] eq "#") {
                        my $tmp = [];

                        for (my $i = 0; $r->[$i]; $i++) {
                            if ($r->[$i]->getAttribute("id") eq $m->[2]) {
                                $tmp = [ $r->[$i] ];
                                last;
                            }
                        }
                        $r = $tmp;
                    }

                    $ret = $r;
                }
            }
        }

        if ($t) {
            my $val = $this->_filter($t, $r);
            $ret = $r = $val->{r};
            $t = $this->_trim($val->{t});
        }
    }
#     $ret = [] if $t;
    die "selector error: $t" if $t;

    shift(@$ret) if $ret and @$ret and $context == $ret->[0];

    $done = $this->_merge($done, $ret);

    return $done;
}

sub _classFilter {
    my ($this, $r, $m, $not) = @_;
    $m = " $m ";
    my $tmp = [];
    for (my $i = 0; $r->[$i]; $i++) {
        my $pass = CORE::index((" " . $r->[$i]->className . " "), $m) >= 0;
        push @$tmp, $r->[$i]
            if not $not and $pass or $not and not $pass;
    }
    return $tmp;
}

sub _filter {
    my ($this, $t, $r, $not) = @_;

    my $last = '';

    while ($t and $t ne $last) {
        $last = $t;

        my ($p, $m) = ($parse);

        for (my $i = 0; $p->[$i]; $i++) {
            my $re = $p->[$i];
            if ($t =~ s/$re//) {
                $m = [0, $1, $2, $3, $4, $5];
                $m->[2] =~ s/\\//g;
                last;
            }
        }

        last
            if not $m;

        if ( $m->[1] eq ":" && $m->[2] eq "not") {
            $r = ($m->[3] =~ m/$isSimple/o)
                ? $this->_filter($m->[3], $r, 1)->{r}
                : pQuery($r)->not($m->[3]);
        }
        elsif ($m->[1] eq ".") {
            $r = $this->_classFilter($r, $m->[2], $not);
        }
        elsif ($m->[1] eq "[") {
            my ($tmp, $type) = ([], $m->[3]);

            for (my ($i, $rl) = (0, scalar(@$r)); $i < $rl; $i++) {
                my $a = $r->[$i];
                my $z = $a->{($this->_props->{$m->[2]} || $m->[2])};

                if (not defined $z or $m->[2] =~ m/href|src|selected/) {
                    $z = $a->attr($m->[2]);
                }

                if (
                    ((
                        # Selects elements that have the specified attribute.
                        ($type eq "" and defined $z) or
                        # Selects elements that have the specified attribute with
                        # a value exactly equal to a certain value.
                        ($type eq "=" and defined $z and $z eq $m->[5]) or
                        # Select elements that either don’t have the specified attribute,
                        # or do have the specified attribute but not with a certain value.
                        ($type eq "!=" and (not defined $z or $z ne $m->[5])) or
                        # Selects elements that have the specified attribute with a
                        # value beginning exactly with a given string.
                        ($type eq "^=" and defined $z and $z =~ /\A\Q$m->[5]\E/) or
                        # Selects elements that have the specified attribute with
                        # a value ending exactly with a given string (case sensitive)
                        ($type eq '$=' and defined $z and $z =~ /\Q$m->[5]\E\z/) or
                        # Selects elements that have the specified attribute with
                        # a value containing the given substring.
                        ($type eq "*=" and defined $z and $z =~ /\Q$m->[5]\E/) or
                        # Selects elements that have the specified attribute with
                        # a value containing a given word, delimited by spaces.
                        ($type eq "~=" and defined $z and $z =~ /(?:\W|\A)\Q$m->[5]\E(?:\W|\z)/) or
                        # Selects elements that have the specified attribute with
                        # a value either equal to a given string or starting with
                        # that string followed by a hyphen (-).
                        ($type eq "|=" and defined $z and $z =~ /\A\Q$m->[5]\E(?:-|\z)/)
                    ) ? 1 : 0) ^ ($not ? 1 : 0)
                ) { push @$tmp, $a }
            }

            $r = $tmp;
        }
        elsif ($m->[1] eq ":" && $m->[2] eq "nth-child") {
            # XXX - Finish porting this. Not sure how useful it is though...
        }
        else {
            my $fn = $expr->{$m->[1]};
            if (ref($fn) eq "HASH") {
                $fn = $fn->{ $m->[2] };
            }
#                if ( typeof fn == "string" )
#                    fn = eval("false||function(a,i){return " + fn + ";}");
            $fn = sub { 0 }
                if ref($fn) ne 'CODE';
            $r = $this->_grep(
                $r,
                sub {
                    return &$fn($_[0], $_[1], $m, $r);
                },
                $not
            );
        }
    }
    return { r => $r, t => $t };
}

sub _dir {
    # XXX - Port me.
}

sub _nth {
    my ($this, $cur, $result, $dir, $elem) = @_;
    $result ||= 1;
    my $num = 0;

    for (; $cur; $cur = $cur->$dir) {
        last if (ref($cur) and $cur->nodeType == 1 and ++$num == $result);
    }

    return $cur;
}

sub _sibling {
    # XXX - Port me.
}

sub _props {
    return {
        for => "htmlFor",
        class => "className",
#         float => styleFloat,
#         cssFloat => styleFloat,
#         styleFloat => styleFloat,
        innerHTML => "innerHTML",
        className => "className",
        value => "value",
        disabled => "disabled",
        checked => "checked",
        readonly => "readOnly",
        selected => "selected",
        maxlength => "maxLength",
        selectedIndex => "selectedIndex",
        defaultValue => "defaultValue",
        tagName => "tagName",
        nodeName => "nodeName"
    };
}

#------------------------------------------------------------------------------#
# These methods need to go down here because they are Perl builtins.
#------------------------------------------------------------------------------#
sub length { return $#{$_[0]} + 1 }

sub index {
    my ($this, $elem) = @_;
    my $ret = -1;
    $this->each(sub {
        $ret = shift
            if (ref($_) && ref($elem)) ? ($_ == $elem) : ($_ eq $elem);
    });
    return $ret;
}

sub not { # (selector)
    # TODO - An anti-grep??
}

#------------------------------------------------------------------------------#
# Helper functions (not methods)
#------------------------------------------------------------------------------#
sub _new_from_url {
    require Encode;
    my $this = shift;
    my $url = shift;
    my $response = $this->_web_get($url);
    return $this
        unless $response->is_success;
    my $html = Encode::decode_utf8($response->content);
    @$this = pQuery::DOM->fromHTML($html);
    return $this;
}

sub _web_get {
    my $this = shift;
    my $url = shift;
    require LWP::UserAgent;
    $lwp_user_agent ||= LWP::UserAgent->new;

    my $request = HTTP::Request->new(GET => $url);
    my $response = $lwp_user_agent->request($request);
    return $response;
}

sub _to_text {
    my ($elem, $text) = @_;
    if (ref $elem) {
        for my $child (@{$elem->{_content}}) {
            _to_text($child, $text);
        }
    }
    else {
        $$text .= $elem;
    }
}

sub _find_elems {
    my ($elem, $selector, $elems) = @_;
    return unless ref $elem;

    if ($selector =~ /^\w+$/) {
        if ($elem->{_tag} eq $selector) {
            push @$elems, $elem;
        }
    }

    for my $child (@{$elem->{_content}}) {
        _find_elems($child, $selector, $elems);
    }
}

sub DESTROY { delete $my->{$_[0]}; }

#------------------------------------------------------------------------------#
# THE AMAZING PQUERY
#------------------------------------------------------------------------------#
package PQUERY;

sub new {
    my $class = shift;
    my $this = bless [], $class;
    @$this = map 'pQuery'->new($_), @_;
    return $this;
}

sub AUTOLOAD {
    (my $method = $PQUERY::AUTOLOAD) =~ s/.*:://;
    my $this = shift;
    my @args = @_;
    $this->EACH(sub {
        my $i = shift;
        $this->[$i] = $_->$method(@args);
    });
    return $this;
}

sub EACH {
    my ($this, $sub) = @_;
    my $index = 0;
    &$sub($index++) for @$this;
    return $this;
}

sub DESTROY {}

1;
