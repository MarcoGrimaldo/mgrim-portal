-- Content added to the site's hardcoded data after the initial import:
-- Project Euler problems 5 and 6 are solved, problem 7 is in progress.

-- Timeline (newest first): make room at the top for #7 and #6.
update public.hackathons set sort_order = sort_order + 2;

update public.hackathons
set
  dates = 'Done!',
  links = '[{"title": "Web problem", "href": "https://projecteuler.net/problem=5", "icon": "globe"}, {"title": "My solution here", "href": "/notebook/project-euler-5", "icon": "nextjs"}]'
where title = '#5: Smallest multiple';

insert into public.hackathons (title, dates, description, image, links, sort_order) values
  (
    '#7: 10001st prime',
    'Currently working on it...',
    'Find the 10,001st prime number.',
    'https://images.emojiterra.com/google/noto-emoji/unicode-16.0/color/svg/1f6a0.svg',
    '[{"title": "Web problem", "href": "https://projecteuler.net/problem=7", "icon": "globe"}]',
    1
  ),
  (
    '#6: Sum square difference',
    'Done!',
    'Find the difference between the sum of the squares of the first n natural numbers and the square of the sum.',
    'https://images.emojiterra.com/google/noto-emoji/unicode-16.0/color/svg/32-20e3.svg',
    '[{"title": "Web problem", "href": "https://projecteuler.net/problem=6", "icon": "globe"}, {"title": "My solution here", "href": "/notebook/project-euler-6", "icon": "nextjs"}]',
    2
  );

-- Notebook index (oldest first).
insert into public.euler_problems (title, description, link, sort_order) values
  (
    '🔢 Smallest Multiple',
    'Find the smallest positive number that is evenly divisible by all of the numbers from 1 to n, where n is the provided parameter value number.',
    '/notebook/project-euler-5',
    5
  ),
  (
    '🧮 Sum Square Difference',
    'Find the difference between the sum of the squares of the first n natural numbers and the square of the sum.',
    '/notebook/project-euler-6',
    6
  );
