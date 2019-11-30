<!DOCTYPE html>
<html lang="{{ \str_replace('_', '-', app()->getLocale()) }}">
<head>
    @include('layouts.partials.html_header')
</head>

<body>

@include('layouts.partials.main_header')

@yield('main_content')

@section('scripts')
    @include('layouts.partials.scripts')
@show

</body>
</html>
