<template>
  <div class="relative overflow-hidden pt-16 pb-32 space-y-24 bg-gray-50 dark:bg-transparent min-h-[calc(100vh-var(--vp-nav-height))] w-full">
        <div class="relative mx-auto px-4 sm:px-6 lg:px-8 flex flex-col items-center text-center">
          <div class="relative z-10">
            <h1 class="text-6xl md:text-[150px] font-extrabold tracking-tight mb-6">
              <span class="bg-clip-text text-transparent bg-gradient-to-r from-indigo-600 via-purple-600 to-indigo-500 animate-gradient-x">
                Bavard
              </span>
            </h1>
            <p class="mt-4 text-2xl md:text-3xl font-bold text-gray-900 dark:text-gray-100 max-w-3xl mx-auto">
              An Eloquent-inspired ORM for Dart/Flutter
            </p>
            <p class="mt-4 text-lg text-gray-700 dark:text-gray-400 max-w-2xl mx-auto leading-relaxed">
              Simplify interactions with SQLite, PostgreSQL, PowerSync, or any SQL-compatible database. Keep your code clean and readable.
            </p>
            
            <div class="mt-10 flex flex-col sm:flex-row gap-4 justify-center items-center">
              <a href="/bavard/guide/" class="px-8 py-3 rounded-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-lg transition-all shadow-lg hover:shadow-indigo-500/30 transform hover:-translate-y-1 no-underline">
                Get Started
              </a>
              <a href="https://github.com/ILDaviz/bavard" target="_blank" class="px-8 py-3 rounded-full bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-900 dark:text-white font-semibold text-lg transition-all shadow-md transform hover:-translate-y-1 flex items-center gap-2 no-underline border border-gray-200 dark:border-gray-700">
                <svg height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg" class="fill-current"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
                View on GitHub
              </a>
            </div>
          </div>
          <div class="absolute top-0 left-1/2 w-full -translate-x-1/2 h-full z-0 pointer-events-none opacity-20 dark:opacity-10">
             <div class="absolute top-20 left-1/4 w-72 h-72 bg-purple-300 rounded-full filter blur-3xl animate-blob"></div>
             <div class="absolute top-20 right-1/4 w-72 h-72 bg-indigo-300 rounded-full filter blur-3xl animate-blob animation-delay-2000"></div>
             <div class="absolute -bottom-8 left-1/3 w-72 h-72 bg-pink-300 rounded-full filter blur-3xl animate-blob animation-delay-4000"></div>
          </div>
        </div>
    
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
        <!-- Text Content -->
        <div class="space-y-6">
          <h2 class="text-3xl font-bold text-gray-900 dark:text-white">Why "Bavard"?</h2>
          <p class="text-lg text-gray-600 dark:text-gray-400 leading-relaxed">
            In French, <span class="text-indigo-600 dark:text-indigo-400 font-semibold italic">bavard</span> means "talkative" or "chatty". 
          </p>
          <p class="text-lg text-gray-600 dark:text-gray-400 leading-relaxed">
            We chose this name because we believe your data layer should be descriptive and fluent. Bavard turns boring SQL interactions into a natural conversation between your code and your database, making complex queries as easy as a friendly chat.
          </p>
        </div>

        <div class="relative group">
          <div class="absolute -inset-1 bg-gradient-to-r from-indigo-500 to-purple-600 rounded-2xl blur opacity-10 group-hover:opacity-25 transition duration-1000 group-hover:duration-200"></div>
          <div class="relative bg-white dark:bg-gray-900 rounded-xl overflow-hidden shadow-xl border border-gray-200 dark:border-gray-800">
            <div class="bg-gray-50 dark:bg-gray-800/50 px-4 py-3 border-b border-gray-200 dark:border-gray-700 flex items-center gap-2">
              <div class="flex gap-1.5">
                <div class="w-3 h-3 rounded-full bg-red-400"></div>
                <div class="w-3 h-3 rounded-full bg-yellow-400"></div>
                <div class="w-3 h-3 rounded-full bg-green-400"></div>
              </div>
              <span class="ml-4 text-xs text-gray-500 dark:text-gray-400 font-mono">user_repository.dart</span>
            </div>
            <div class="p-6 text-sm font-mono leading-relaxed overflow-x-auto text-gray-800 dark:text-gray-200">
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">1</span>
                <span><span class="text-indigo-600 dark:text-purple-400 font-semibold">final</span> users = <span class="text-indigo-600 dark:text-purple-400 font-semibold">await</span> User()</span>
              </div>
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">2</span>
                <span class="pl-4">.query()</span>
              </div>
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">3</span>
                <span class="pl-4">.where(User.schema.age.greaterThan(<span class="text-orange-600 dark:text-orange-300">18</span>))</span>
              </div>
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">4</span>
                <span class="pl-4">.where(User.schema.isActive.equals(<span class="text-orange-600 dark:text-orange-300">true</span>))</span>
              </div>
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">5</span>
                <span class="pl-4">.withRelations([<span class="text-green-600 dark:text-green-300">'posts'</span>, <span class="text-green-600 dark:text-green-300">'profile'</span>])</span>
              </div>
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">6</span>
                <span class="pl-4">.orderByDesc(User.schema.createdAt)</span>
              </div>
              <div class="flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">7</span>
                <span class="pl-4">.get();</span>
              </div>
              <div class="mt-4 flex gap-4">
                <span class="text-gray-400 dark:text-gray-500 select-none">8</span>
                <span class="text-gray-500 dark:text-gray-400 italic">// It's that simple. 💬</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <a href="/bavard/guide/installation" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🦋
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Flutter ready</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Seamlessly integrated with Flutter for mobile, desktop, and web applications.
              </p>
            </a>
            <a href="/bavard/core/query-builder" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🪄
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Fluent query builder</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Write readable queries like <code class="text-xs bg-gray-100 dark:bg-gray-900 px-1 py-0.5 rounded text-indigo-600 dark:text-indigo-400 font-medium">User().query().where(...).get()</code>.
              </p>
            </a>
            <a href="/bavard/core/crud" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🔄
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Active record pattern</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Models are responsible for saving themselves. <code class="text-xs bg-gray-100 dark:bg-gray-900 px-1 py-0.5 rounded text-indigo-600 dark:text-indigo-400 font-medium">user.save()</code>, <code class="text-xs bg-gray-100 dark:bg-gray-900 px-1 py-0.5 rounded text-indigo-600 dark:text-indigo-400 font-medium">user.delete()</code>.
              </p>
            </a>
            <a href="/bavard/reference/adapters" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🧩
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Driver agnostic</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Works with any database driver via the <code class="text-xs bg-gray-100 dark:bg-gray-900 px-1 py-0.5 rounded text-indigo-600 dark:text-indigo-400 font-medium">DatabaseAdapter</code> interface.
              </p>
            </a>
            <a href="/bavard/relationships/" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🔗
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Powerful relations</h3>
              <p class="text-gray-600 dark:text-gray-400">
                HasOne, HasMany, BelongsTo, ManyToMany, and Polymorphic relations supported out of the box.
              </p>
            </a>
            <a href="/bavard/tooling/code-generation" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                ✨
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">No Code Gen Required</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Code generation is completely optional. Bavard works entirely at runtime, giving you a faster development workflow.
              </p>
            </a>
            <a href="/bavard/advanced/uuids" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                📡
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Offline-first ready</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Native support for client-side UUIDs and driver-agnostic architecture, perfect for local-first apps.
              </p>
            </a>
            <a href="/bavard/advanced/soft-deletes" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🏭
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Production-ready</h3>
              <p class="text-gray-600 dark:text-gray-400">
                Built-in support for soft deletes, automatic timestamps, and global scopes out of the box.
              </p>
            </a>
            <a href="/bavard/advanced/type-casting" class="p-6 rounded-2xl bg-white dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-xl hover:border-indigo-500/50 transition-all duration-300 group no-underline">
              <div class="w-12 h-12 mb-4 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform duration-300">
                🎭
              </div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Smart Data Casting</h3>
              <p class="text-gray-600 dark:text-gray-400">
                 Automatic hydration of complex types like JSON, DateTime, and Booleans between Dart and your database.
              </p>
            </a>
          </div>
        </div>
  </div>
</template>

    

          

<style scoped>
@keyframes blob {
  0% { transform: translate(0px, 0px) scale(1); }
  33% { transform: translate(30px, -50px) scale(1.1); }
  66% { transform: translate(-20px, 20px) scale(0.9); }
  100% { transform: translate(0px, 0px) scale(1); }
}
.animate-blob {
  animation: blob 7s infinite;
}
.animation-delay-2000 {
  animation-delay: 2s;
}
.animation-delay-4000 {
  animation-delay: 4s;
}

@keyframes gradient-x {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}
.animate-gradient-x {
  background-size: 200% auto;
  animation: gradient-x 4s linear infinite;
}
</style>
