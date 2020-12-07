@extends('layouts.app', ['page_title' => 'Welcome!'])

@section('html_header')
<!-- Additional header tags -->
@endsection

@section('main_content')

    <h1 class="text-center">
        You'r welcome!
    </h1>

    <h5 class="text-center">
        Laravel v{{ Illuminate\Foundation\Application::VERSION }} (PHP v{{ PHP_VERSION }})
    </h5>

@endsection
