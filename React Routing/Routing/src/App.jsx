import { useState } from 'react'
import './App.css'
import Navbar from './Components/Navbar'
import Home from './Components/Home'
import About from './Components/About'
import Contact from './Components/Conteact'
import { Routes, Route } from 'react-router-dom'   

function App() {

  return (
    <>
      <Navbar />

      {/* ✅ Use Routes instead of Routers */}
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/contact" element={<Contact />} />
      </Routes>

      
      {/* <h1> Welcome to React Routing</h1>
      <Home />
      <About />
      <Contact /> */}
    </>
  )
}

export default App
