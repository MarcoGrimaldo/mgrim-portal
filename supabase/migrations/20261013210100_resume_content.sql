-- Initial content, copied from the former hardcoded DATA object in src/data/resume.tsx.
-- Runs once per environment; later edits happen in the Supabase dashboard.

insert into public.profile
  (name, initials, url, location, location_link, description, summary, avatar_url, email, tel)
values (
  'Marco Grimaldo',
  'MG',
  'https://mgrim.dev',
  'México',
  'https://www.google.com/maps/place/Ciudad+de+México',
  'Software Engineer. I love building things and helping people.',
  'In 2021, I start working as a software engineer, I began focusing on creating meaningful digital experiences through my own projects. I spend my free time building and learning new tools every day — always exploring better ways to solve problems and bring ideas to life online.',
  '/yop.png',
  'hello@example.com',
  '+123456789'
);

insert into public.social_links (name, url, icon, navbar, sort_order) values
  ('GitHub', 'https://github.com/MarcoGrimaldo', 'github', true, 1),
  ('LinkedIn', 'https://www.linkedin.com/in/marco-a-grimaldo-peralta-83468a1a2/', 'linkedin', true, 2),
  ('Resume', 'https://drive.google.com/file/d/1R2FPRV0dhoWyOqVfgfuu_-cEEha0E_2W/view?usp=sharing', 'resume', true, 3);

insert into public.skills (name, category, sort_order) values
  ('React', 'dev', 1),
  ('React Native', 'dev', 2),
  ('Next.js', 'dev', 3),
  ('Vite', 'dev', 4),
  ('Redux', 'dev', 5),
  ('Typescript', 'dev', 6),
  ('Material UI', 'dev', 7),
  ('Node.js', 'dev', 8),
  ('Jest', 'dev', 9),
  ('Vitest', 'dev', 10),
  ('Python', 'dev', 11),
  ('JavaScript', 'dev', 12),
  ('Postgres', 'dev', 13),
  ('PL/SQL', 'dev', 14),
  ('Java', 'dev', 15),
  ('C++', 'dev', 16),
  ('Dart', 'dev', 17),
  ('PHP', 'dev', 18),
  ('Jira', 'tools', 1),
  ('Git', 'tools', 2),
  ('GitHub', 'tools', 3),
  ('Vercel', 'tools', 4),
  ('Microsoft Azure', 'tools', 5),
  ('AWS', 'tools', 6),
  ('Storybook', 'tools', 7),
  ('Docker', 'tools', 8),
  ('Zeplin', 'tools', 9),
  ('Figma', 'tools', 10);

insert into public.work
  (company, href, location, title, logo_url, period_start, period_end, description, sort_order)
values
  (
    'PSL Group',
    'https://www.pslgroup.com/',
    'Remote',
    'Application Developer',
    '/psl_group_logo.jpeg',
    'January 2022',
    'up to now',
    'Experienced Front-End Developer skilled in building responsive, scalable web applications using React. Proficient in creating reusable components, custom hooks, and debugging complex UI issues. Successfully deployed and maintained 15+ websites on AWS, ensuring high performance, reliability, and maintainable code.',
    1
  ),
  (
    'Veyron',
    'https://veyron.com.mx/',
    'Hybrid',
    'Software Developer',
    '/veyron.png',
    'June 2021',
    'Jan 2022',
    'Full-Stack Developer with ERP Expertise, experienced in customizing IFS ERP solutions using IFS Developer Studio, .NET Core, and PL/SQL. Designed efficient backend logic and robust database components, while building custom web portals for seamless ERP data access. Skilled in front-end development with JavaScript, jQuery, Telerik, and responsive design. Integrated SOAP services and championed modernization efforts by introducing React and React Native for web and mobile solutions.',
    2
  ),
  (
    'CIITA Chihuahua',
    'https://www.ciitachihuahua.ipn.mx/',
    'Remote',
    'Front End Developer',
    '/images.png',
    'January 2021',
    'June 2021',
    'Web Developer for Research Institutions, led the development of the CIITA Chihuahua website for the National Polytechnic Institute. Built a responsive and dynamic web app using React, Node.js, and CSS. Collaborated on intuitive UI design tailored to academic needs, ensured smooth version control with Git, and delivered a scalable, maintainable solution to support the center’s digital presence.',
    3
  );

insert into public.education
  (school, href, degree, logo_url, period_start, period_end, sort_order)
values
  (
    'School of Computer Science and Engineering',
    'https://www.escom.ipn.mx/',
    'Bachelor’s Degree in Computer Systems Engineering',
    '/escom.jpeg',
    '2017',
    '2021',
    1
  ),
  (
    'Udemy Courses',
    'https://www.udemy.com/',
    'Ongoing Professional Development',
    '/udemy_logo.jpeg',
    '2021',
    'up to now',
    2
  );

insert into public.projects
  (title, href, dates, active, description, technologies, links, image, video, sort_order)
values
  (
    'Grupo Garruz',
    'https://www.grupogarruz.com/',
    'Jan 2025 - Feb 2025',
    true,
    'Developed a responsive website to showcase a construction consultancy’s services, helping them attract clients and improve their digital presence.',
    array['React', 'Javascript', 'Node.js', 'Material UI', 'Vercel', 'Sora'],
    '[{"type": "Website", "href": "https://www.grupogarruz.com/", "icon": "globe"}]',
    '',
    '/garruz.mov',
    1
  ),
  (
    'Griza',
    'https://griza-corp.vercel.app/',
    'June 2022 - September 2022',
    true,
    'Built a startup site to sell sleek, ready-to-use website templates for businesses looking to get online quickly and affordably.',
    array['Javascript', 'React', 'HTML', 'Bootstrap', 'CSS', 'Vercel', 'GitHub Pages'],
    '[{"type": "Website", "href": "https://griza-corp.vercel.app/", "icon": "globe"}, {"type": "Source", "href": "https://github.com/MarcoGrimaldo/griza-corp", "icon": "github"}]',
    '',
    '/griza1.mov',
    2
  ),
  (
    'Old Portafolio',
    'https://marcogrimaldo.github.io/portafolio/',
    'April 2020 - September 2020',
    true,
    'Built my first portfolio website to showcase personal projects, skills, and experience as a software developer, using a clean, responsive design.',
    array['jQuery', 'Javascript', 'HTML', 'CSS', 'Git Hub Pages'],
    '[{"type": "Website", "href": "https://marcogrimaldo.github.io/portafolio/", "icon": "globe"}]',
    '',
    '/yop.mov',
    3
  ),
  (
    'Recorre Teotihuacán',
    'https://marcogrimaldo.github.io/recorre-teoti/#/',
    'April 2020 - March 2020',
    true,
    'Developed a tourism services website with support for showcasing destinations and managing reservations through a user-friendly interface.',
    array['Javascript', 'React', 'Materialize CSS', 'Redux', 'Github Pages'],
    '[{"type": "Website", "href": "https://marcogrimaldo.github.io/recorre-teoti/#/", "icon": "globe"}, {"type": "Source", "href": "https://github.com/MarcoGrimaldo/recorre-teoti/tree/master", "icon": "github"}]',
    '',
    '/recorre1.mov',
    4
  );

insert into public.hackathons (title, dates, description, image, links, sort_order) values
  (
    '#5: Smallest multiple',
    'Currently working on...',
    'Find smallest positive number that is evenly divisible by all of the numbers from 1 to n.',
    'https://images.emojiterra.com/google/noto-emoji/unicode-16.0/color/svg/1f96b.svg',
    '[{"title": "Web problem", "href": "https://projecteuler.net/problem=5", "icon": "globe"}]',
    1
  ),
  (
    '#4: Largest palindrome product',
    'Done!',
    'Find the largest palindrome made from the product of two n-digit numbers.',
    'https://images.emojiterra.com/google/noto-emoji/unicode-16.0/color/svg/1f504.svg',
    '[{"title": "Web problem", "href": "https://projecteuler.net/problem=4", "icon": "globe"}, {"title": "My solution here", "href": "/notebook/project-euler-4", "icon": "nextjs"}]',
    2
  ),
  (
    '#3: Largest Prime Factor',
    'Done!',
    'What is the largest prime factor of the given number?',
    'https://images.emojiterra.com/google/noto-emoji/unicode-16.0/color/svg/26f8.svg',
    '[{"title": "Web problem", "href": "https://projecteuler.net/problem=3", "icon": "globe"}, {"title": "My solution here", "href": "/notebook/project-euler-3", "icon": "nextjs"}]',
    3
  );

insert into public.euler_problems (title, description, link, sort_order) values
  (
    '🔢 Multiples of 3 and 5',
    'Find the sum of all the multiples of 3 or 5 below the provided parameter value number.',
    '/notebook/project-euler-1',
    1
  ),
  (
    '🇮🇹 Even Fibonacci numbers',
    'Return the sum of all even Fibonacci numbers that are less than or equal to the provided parameter value number.',
    '/notebook/project-euler-2',
    2
  ),
  (
    '⬆️ Largest Prime Factor',
    'What is the largest prime factor of the provided parameter value number?',
    '/notebook/project-euler-3',
    3
  ),
  (
    '🆘 Largest Palindrome Product',
    'Find the largest palindrome made from the product of two n-digit numbers, where n is the provided parameter value number.',
    '/notebook/project-euler-4',
    4
  );
